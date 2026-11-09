import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  AppState,
  AutomationRule,
  DeviceAction,
  DeviceKind,
  DeviceState,
  EnvironmentState,
  ExecutionRecord,
  MetricField,
  ComparisonOperator,
  RuleCondition,
  ScenePreset
} from '../model/Domain';

export class PersistenceService {
  private readonly storeName: string = 'smart_dorm_rule_lab';
  private readonly stateKey: string = 'app_state_v1';
  private store: preferences.Preferences | null = null;

  async load(context: common.UIAbilityContext): Promise<AppState | null> {
    try {
      this.store = await preferences.getPreferences(context, { name: this.storeName });
      let stored: preferences.ValueType = await this.store.get(this.stateKey, '');
      if (typeof stored !== 'string' || stored.length === 0) {
        return null;
      }
      return this.decode(stored);
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`Load preferences failed: ${businessError.code} ${businessError.message}`);
      return null;
    }
  }

  async save(context: common.UIAbilityContext, state: AppState): Promise<void> {
    try {
      if (this.store === null) {
        this.store = await preferences.getPreferences(context, { name: this.storeName });
      }
      await this.store.put(this.stateKey, JSON.stringify(state));
      await this.store.flush();
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`Save preferences failed: ${businessError.code} ${businessError.message}`);
    }
  }

  private decode(raw: string): AppState {
    let parsed: AppState = JSON.parse(raw) as AppState;
    let environment: EnvironmentState = new EnvironmentState(
      parsed.environment.temperature,
      parsed.environment.humidity,
      parsed.environment.illuminance,
      parsed.environment.occupied
    );
    let devices: DeviceState = new DeviceState(
      parsed.devices.lightLevel,
      parsed.devices.fanLevel,
      parsed.devices.curtainPosition,
      parsed.devices.airConditionerTarget
    );

    let rules: AutomationRule[] = [];
    for (let index: number = 0; index < parsed.rules.length; index++) {
      let item: AutomationRule = parsed.rules[index];
      let conditions: RuleCondition[] = [];
      for (let conditionIndex: number = 0; conditionIndex < item.conditions.length; conditionIndex++) {
        let sourceCondition: RuleCondition = item.conditions[conditionIndex];
        conditions.push(new RuleCondition(
          sourceCondition.field as MetricField,
          sourceCondition.operator as ComparisonOperator,
          sourceCondition.value
        ));
      }
      rules.push(new AutomationRule(
        item.id,
        item.name,
        conditions,
        new DeviceAction(item.action.device as DeviceKind, item.action.value),
        item.priority,
        item.enabled,
        item.createdAt
      ));
    }

    let scenes: ScenePreset[] = [];
    for (let index: number = 0; index < parsed.scenes.length; index++) {
      let item: ScenePreset = parsed.scenes[index];
      scenes.push(new ScenePreset(
        item.id,
        item.name,
        item.description,
        new EnvironmentState(
          item.environment.temperature,
          item.environment.humidity,
          item.environment.illuminance,
          item.environment.occupied
        ),
        new DeviceState(
          item.devices.lightLevel,
          item.devices.fanLevel,
          item.devices.curtainPosition,
          item.devices.airConditionerTarget
        ),
        item.savedAt
      ));
    }

    let logs: ExecutionRecord[] = [];
    for (let index: number = 0; index < parsed.logs.length; index++) {
      let item: ExecutionRecord = parsed.logs[index];
      logs.push(new ExecutionRecord(
        item.id,
        item.timeLabel,
        item.source,
        item.matchedRuleNames.slice(),
        item.executedActions.slice(),
        item.skippedActions.slice(),
        item.conditionSummary,
        item.deviceSummary
      ));
    }

    return new AppState(environment, devices, rules, scenes, logs,
      parsed.lastRunAt ?? '尚未运行', parsed.schemaVersion ?? 1);
  }
}
