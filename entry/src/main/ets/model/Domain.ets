export enum MetricField {
  TEMPERATURE = 'temperature',
  HUMIDITY = 'humidity',
  ILLUMINANCE = 'illuminance',
  OCCUPIED = 'occupied'
}

export enum ComparisonOperator {
  GT = '>',
  GTE = '>=',
  LT = '<',
  LTE = '<='
}

export enum DeviceKind {
  LIGHT = 'light',
  FAN = 'fan',
  CURTAIN = 'curtain',
  AIR_CONDITIONER = 'airConditioner'
}

@Observed
export class EnvironmentState {
  temperature: number;
  humidity: number;
  illuminance: number;
  occupied: boolean;

  constructor(temperature: number = 26, humidity: number = 58, illuminance: number = 420,
    occupied: boolean = true) {
    this.temperature = temperature;
    this.humidity = humidity;
    this.illuminance = illuminance;
    this.occupied = occupied;
  }

  clone(): EnvironmentState {
    return new EnvironmentState(this.temperature, this.humidity, this.illuminance, this.occupied);
  }
}

@Observed
export class DeviceState {
  lightLevel: number;
  fanLevel: number;
  curtainPosition: number;
  airConditionerTarget: number;

  constructor(lightLevel: number = 60, fanLevel: number = 0, curtainPosition: number = 30,
    airConditionerTarget: number = 26) {
    this.lightLevel = lightLevel;
    this.fanLevel = fanLevel;
    this.curtainPosition = curtainPosition;
    this.airConditionerTarget = airConditionerTarget;
  }

  clone(): DeviceState {
    return new DeviceState(this.lightLevel, this.fanLevel, this.curtainPosition, this.airConditionerTarget);
  }

  summary(): string {
    let lightText: string = this.lightLevel > 0 ? `灯光 ${this.lightLevel}%` : '灯光关闭';
    let fanText: string = this.fanLevel > 0 ? `风扇 ${this.fanLevel} 档` : '风扇关闭';
    let airText: string = this.airConditionerTarget > 0 ? `空调 ${this.airConditionerTarget}°C` : '空调关闭';
    return `${lightText}，${fanText}，窗帘 ${this.curtainPosition}%，${airText}`;
  }
}

export class RuleCondition {
  field: MetricField;
  operator: ComparisonOperator;
  value: number;

  constructor(field: MetricField, operator: ComparisonOperator, value: number) {
    this.field = field;
    this.operator = operator;
    this.value = value;
  }

  clone(): RuleCondition {
    return new RuleCondition(this.field, this.operator, this.value);
  }
}

export class DeviceAction {
  device: DeviceKind;
  value: number;

  constructor(device: DeviceKind, value: number) {
    this.device = device;
    this.value = value;
  }

  clone(): DeviceAction {
    return new DeviceAction(this.device, this.value);
  }
}

export class AutomationRule {
  id: string;
  name: string;
  conditions: RuleCondition[];
  action: DeviceAction;
  priority: number;
  enabled: boolean;
  createdAt: number;

  constructor(id: string, name: string, conditions: RuleCondition[], action: DeviceAction,
    priority: number, enabled: boolean = true, createdAt: number = Date.now()) {
    this.id = id;
    this.name = name;
    this.conditions = conditions;
    this.action = action;
    this.priority = priority;
    this.enabled = enabled;
    this.createdAt = createdAt;
  }

  clone(): AutomationRule {
    let conditionCopies: RuleCondition[] = [];
    for (let index: number = 0; index < this.conditions.length; index++) {
      conditionCopies.push(this.conditions[index].clone());
    }
    return new AutomationRule(this.id, this.name, conditionCopies, this.action.clone(),
      this.priority, this.enabled, this.createdAt);
  }
}

@Observed
export class ScenePreset {
  id: string;
  name: string;
  description: string;
  environment: EnvironmentState;
  devices: DeviceState;
  savedAt: number;

  constructor(id: string, name: string, description: string, environment: EnvironmentState,
    devices: DeviceState, savedAt: number = Date.now()) {
    this.id = id;
    this.name = name;
    this.description = description;
    this.environment = environment;
    this.devices = devices;
    this.savedAt = savedAt;
  }
}

export class MockEnvironmentScenario {
  id: string;
  name: string;
  description: string;
  environment: EnvironmentState;

  constructor(id: string, name: string, description: string, environment: EnvironmentState) {
    this.id = id;
    this.name = name;
    this.description = description;
    this.environment = environment;
  }
}

export class ExecutionRecord {
  id: string;
  timeLabel: string;
  source: string;
  matchedRuleNames: string[];
  executedActions: string[];
  skippedActions: string[];
  conditionSummary: string;
  deviceSummary: string;

  constructor(id: string, timeLabel: string, source: string, matchedRuleNames: string[],
    executedActions: string[], skippedActions: string[], conditionSummary: string,
    deviceSummary: string) {
    this.id = id;
    this.timeLabel = timeLabel;
    this.source = source;
    this.matchedRuleNames = matchedRuleNames;
    this.executedActions = executedActions;
    this.skippedActions = skippedActions;
    this.conditionSummary = conditionSummary;
    this.deviceSummary = deviceSummary;
  }
}

export class EvaluationResult {
  matchedCount: number;
  executedCount: number;
  skippedCount: number;
  record: ExecutionRecord;

  constructor(matchedCount: number, executedCount: number, skippedCount: number,
    record: ExecutionRecord) {
    this.matchedCount = matchedCount;
    this.executedCount = executedCount;
    this.skippedCount = skippedCount;
    this.record = record;
  }
}

export class AppState {
  schemaVersion: number;
  environment: EnvironmentState;
  devices: DeviceState;
  rules: AutomationRule[];
  scenes: ScenePreset[];
  logs: ExecutionRecord[];
  lastRunAt: string;

  constructor(environment: EnvironmentState, devices: DeviceState, rules: AutomationRule[],
    scenes: ScenePreset[], logs: ExecutionRecord[], lastRunAt: string = '尚未运行',
    schemaVersion: number = 1) {
    this.schemaVersion = schemaVersion;
    this.environment = environment;
    this.devices = devices;
    this.rules = rules;
    this.scenes = scenes;
    this.logs = logs;
    this.lastRunAt = lastRunAt;
  }

  clone(): AppState {
    let ruleCopies: AutomationRule[] = [];
    for (let index: number = 0; index < this.rules.length; index++) {
      ruleCopies.push(this.rules[index].clone());
    }
    let sceneCopies: ScenePreset[] = [];
    for (let index: number = 0; index < this.scenes.length; index++) {
      let scene: ScenePreset = this.scenes[index];
      sceneCopies.push(new ScenePreset(scene.id, scene.name, scene.description,
        scene.environment.clone(), scene.devices.clone(), scene.savedAt));
    }
    return new AppState(this.environment.clone(), this.devices.clone(), ruleCopies, sceneCopies,
      this.logs.slice(), this.lastRunAt, this.schemaVersion);
  }
}
