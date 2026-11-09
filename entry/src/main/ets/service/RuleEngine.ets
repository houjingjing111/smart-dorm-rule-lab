import {
  AppState,
  AutomationRule,
  ComparisonOperator,
  DeviceAction,
  DeviceKind,
  EvaluationResult,
  ExecutionRecord,
  MetricField,
  RuleCondition
} from '../model/Domain';

export class RuleEngine {
  static evaluate(state: AppState, source: string = '环境变化'): EvaluationResult {
    let matched: AutomationRule[] = [];
    for (let index: number = 0; index < state.rules.length; index++) {
      let rule: AutomationRule = state.rules[index];
      if (rule.enabled && RuleEngine.matchesAll(state, rule.conditions)) {
        matched.push(rule);
      }
    }

    matched.sort((left: AutomationRule, right: AutomationRule): number => {
      if (right.priority !== left.priority) {
        return right.priority - left.priority;
      }
      return left.createdAt - right.createdAt;
    });

    let claimedDevices: Map<string, string> = new Map<string, string>();
    let executedActions: string[] = [];
    let skippedActions: string[] = [];
    let matchedNames: string[] = [];
    let conditionParts: string[] = [];

    for (let ruleIndex: number = 0; ruleIndex < matched.length; ruleIndex++) {
      let rule: AutomationRule = matched[ruleIndex];
      matchedNames.push(rule.name);
      conditionParts.push(`${ruleIndex + 1}. ${rule.name}：${RuleEngine.describeConditions(rule.conditions)}`);
      let action: DeviceAction = rule.action;
      let deviceKey: string = action.device;
      if (claimedDevices.has(deviceKey)) {
        let owner: string = claimedDevices.get(deviceKey) ?? '更高优先级规则';
        let skippedText: string =
          `${rule.name} 的 ${RuleEngine.actionDescription(action)} 被 ${owner} 覆盖`;
        skippedActions.push(skippedText);
        continue;
      }

      claimedDevices.set(deviceKey, rule.name);
      RuleEngine.applyAction(state, action);
      executedActions.push(`${ruleIndex + 1}. ${RuleEngine.actionDescription(action)}（优先级 ${rule.priority}）`);
    }

    let now: Date = new Date();
    let timeLabel: string = RuleEngine.formatTime(now);
    let record: ExecutionRecord = new ExecutionRecord(
      `run-${now.getTime()}-${Math.floor(Math.random() * 1000)}`,
      timeLabel,
      source,
      matchedNames,
      executedActions,
      skippedActions,
      conditionParts.length > 0 ? conditionParts.join('；') : '未命中任何启用规则',
      state.devices.summary()
    );
    state.logs.unshift(record);
    if (state.logs.length > 30) {
      state.logs = state.logs.slice(0, 30);
    }
    state.lastRunAt = timeLabel;
    return new EvaluationResult(matched.length, executedActions.length, skippedActions.length, record);
  }

  static matchesAll(state: AppState, conditions: RuleCondition[]): boolean {
    if (conditions.length === 0) {
      return false;
    }
    for (let index: number = 0; index < conditions.length; index++) {
      if (!RuleEngine.matches(state, conditions[index])) {
        return false;
      }
    }
    return true;
  }

  static matches(state: AppState, condition: RuleCondition): boolean {
    let actual: number = RuleEngine.metricValue(state, condition.field);
    if (condition.operator === ComparisonOperator.GT) {
      return actual > condition.value;
    }
    if (condition.operator === ComparisonOperator.GTE) {
      return actual >= condition.value;
    }
    if (condition.operator === ComparisonOperator.LT) {
      return actual < condition.value;
    }
    return actual <= condition.value;
  }

  static metricValue(state: AppState, field: MetricField): number {
    if (field === MetricField.TEMPERATURE) {
      return state.environment.temperature;
    }
    if (field === MetricField.HUMIDITY) {
      return state.environment.humidity;
    }
    if (field === MetricField.ILLUMINANCE) {
      return state.environment.illuminance;
    }
    return state.environment.occupied ? 1 : 0;
  }

  static applyAction(state: AppState, action: DeviceAction): void {
    if (action.device === DeviceKind.LIGHT) {
      state.devices.lightLevel = RuleEngine.clamp(action.value, 0, 100);
      return;
    }
    if (action.device === DeviceKind.FAN) {
      state.devices.fanLevel = RuleEngine.clamp(action.value, 0, 3);
      return;
    }
    if (action.device === DeviceKind.CURTAIN) {
      state.devices.curtainPosition = RuleEngine.clamp(action.value, 0, 100);
      return;
    }
    if (action.value <= 0) {
      state.devices.airConditionerTarget = 0;
    } else {
      state.devices.airConditionerTarget = RuleEngine.clamp(action.value, 16, 30);
    }
  }

  static clamp(value: number, minimum: number, maximum: number): number {
    if (value < minimum) {
      return minimum;
    }
    if (value > maximum) {
      return maximum;
    }
    return value;
  }

  static actionDescription(action: DeviceAction): string {
    if (action.device === DeviceKind.LIGHT) {
      return action.value <= 0 ? '关闭灯光' : `灯光调到 ${action.value}%`;
    }
    if (action.device === DeviceKind.FAN) {
      return action.value <= 0 ? '关闭风扇' : `风扇调到 ${action.value} 档`;
    }
    if (action.device === DeviceKind.CURTAIN) {
      return `窗帘调整到 ${action.value}%`;
    }
    return action.value <= 0 ? '关闭空调' : `空调设为 ${action.value}°C`;
  }

  static fieldName(field: MetricField): string {
    if (field === MetricField.TEMPERATURE) {
      return '温度';
    }
    if (field === MetricField.HUMIDITY) {
      return '湿度';
    }
    if (field === MetricField.ILLUMINANCE) {
      return '照度';
    }
    return '有人';
  }

  static conditionDescription(condition: RuleCondition): string {
    if (condition.field === MetricField.OCCUPIED) {
      let occupiedText: string = condition.value >= 1 ? '有人' : '无人';
      return `${RuleEngine.fieldName(condition.field)}${condition.operator}${occupiedText}`;
    }
    let unit: string = '%';
    if (condition.field === MetricField.TEMPERATURE) {
      unit = '°C';
    } else if (condition.field === MetricField.ILLUMINANCE) {
      unit = ' lx';
    }
    return `${RuleEngine.fieldName(condition.field)}${condition.operator}${condition.value}${unit}`;
  }

  static describeConditions(conditions: RuleCondition[]): string {
    let descriptions: string[] = [];
    for (let index: number = 0; index < conditions.length; index++) {
      descriptions.push(RuleEngine.conditionDescription(conditions[index]));
    }
    return descriptions.join(' 且 ');
  }

  private static formatTime(date: Date): string {
    let month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    let day: string = `${date.getDate()}`.padStart(2, '0');
    let hour: string = `${date.getHours()}`.padStart(2, '0');
    let minute: string = `${date.getMinutes()}`.padStart(2, '0');
    let second: string = `${date.getSeconds()}`.padStart(2, '0');
    return `${month}-${day} ${hour}:${minute}:${second}`;
  }
}
