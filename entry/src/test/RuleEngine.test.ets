import { describe, expect, it } from '@ohos/hypium';
import {
  AppState,
  ComparisonOperator,
  DeviceAction,
  DeviceKind,
  MetricField,
  RuleCondition
} from '../main/ets/model/Domain';
import { MockData } from '../main/ets/model/MockData';
import { RuleEngine } from '../main/ets/service/RuleEngine';

export default function ruleEngineTest() {
  describe('SmartDormRuleEngine', () => {
    it('normal_dualConditionStartsAirConditioner', 0, () => {
      let state: AppState = MockData.createDefaultState();
      state.environment.temperature = 30;
      state.environment.occupied = true;
      RuleEngine.evaluate(state, 'normal');
      expect(state.devices.airConditionerTarget).assertEqual(24);
      expect(state.logs.length).assertEqual(1);
    });

    it('normal_emptyRoomSkipsOccupancyRules', 0, () => {
      let state: AppState = MockData.createDefaultState();
      state.environment.temperature = 30;
      state.environment.occupied = false;
      RuleEngine.evaluate(state, 'empty');
      expect(state.devices.airConditionerTarget).assertEqual(26);
      expect(state.logs[0].matchedRuleNames.indexOf('高温且有人在寝时启动空调')).assertEqual(-1);
    });

    it('boundary_humidityAtSeventyTriggersVentilation', 0, () => {
      let state: AppState = MockData.createDefaultState();
      state.environment.humidity = 70;
      RuleEngine.evaluate(state, 'boundary-humidity');
      expect(state.devices.fanLevel).assertEqual(2);
    });

    it('boundary_illuminanceAtEightyDoesNotTriggerNightLight', 0, () => {
      let state: AppState = MockData.createDefaultState();
      state.environment.illuminance = 80;
      state.environment.occupied = true;
      RuleEngine.evaluate(state, 'boundary-light');
      expect(state.devices.lightLevel).assertEqual(45);

      state.environment.illuminance = 79;
      RuleEngine.evaluate(state, 'boundary-light-lower');
      expect(state.devices.lightLevel).assertEqual(35);
    });

    it('conflict_higherPriorityOwnsSharedDevice', 0, () => {
      let state: AppState = MockData.createDefaultState();
      state.environment.temperature = 33;
      state.environment.humidity = 78;
      state.environment.illuminance = 720;
      state.environment.occupied = true;
      let result = RuleEngine.evaluate(state, 'conflict');
      expect(state.devices.fanLevel).assertEqual(2);
      expect(result.skippedCount).assertEqual(1);
      expect(result.record.skippedActions[0].indexOf('高温节能优先使用低档风扇')).assertEqual(0);
    });

    it('exception_disabledRuleIsIgnored', 0, () => {
      let state: AppState = MockData.createDefaultState();
      state.environment.temperature = 35;
      state.rules[0].enabled = false;
      RuleEngine.evaluate(state, 'disabled');
      expect(state.devices.airConditionerTarget).assertEqual(26);
    });

    it('exception_noRuleMatchesKeepsDevicesUnchanged', 0, () => {
      let state: AppState = MockData.createDefaultState();
      state.environment.temperature = 20;
      state.environment.humidity = 50;
      state.environment.illuminance = 100;
      state.environment.occupied = false;
      let result = RuleEngine.evaluate(state, 'no-match');
      expect(result.matchedCount).assertEqual(0);
      expect(state.devices.summary()).assertEqual('灯光 45%，风扇 1 档，窗帘 35%，空调 26°C');
    });

    it('exception_invalidActionValueIsClamped', 0, () => {
      let state: AppState = MockData.createDefaultState();
      RuleEngine.applyAction(state, new DeviceAction(DeviceKind.FAN, 9));
      RuleEngine.applyAction(state, new DeviceAction(DeviceKind.AIR_CONDITIONER, 40));
      RuleEngine.applyAction(state, new DeviceAction(DeviceKind.LIGHT, -8));
      expect(state.devices.fanLevel).assertEqual(3);
      expect(state.devices.airConditionerTarget).assertEqual(30);
      expect(state.devices.lightLevel).assertEqual(0);

      let condition: RuleCondition =
        new RuleCondition(MetricField.TEMPERATURE, ComparisonOperator.LTE, 30);
      expect(RuleEngine.matches(state, condition)).assertTrue();
    });
  });
}
