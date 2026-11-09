import {
  AppState,
  AutomationRule,
  ComparisonOperator,
  DeviceAction,
  DeviceKind,
  DeviceState,
  EnvironmentState,
  MetricField,
  MockEnvironmentScenario,
  RuleCondition,
  ScenePreset
} from './Domain';

export class MockData {
  static createDefaultState(): AppState {
    let environment: EnvironmentState = new EnvironmentState(27, 64, 520, true);
    let devices: DeviceState = new DeviceState(45, 1, 35, 26);

    let rules: AutomationRule[] = [
      new AutomationRule(
        'rule-cooling',
        '高温且有人在寝时启动空调',
        [
          new RuleCondition(MetricField.TEMPERATURE, ComparisonOperator.GTE, 28),
          new RuleCondition(MetricField.OCCUPIED, ComparisonOperator.GTE, 1)
        ],
        new DeviceAction(DeviceKind.AIR_CONDITIONER, 24),
        5,
        true
      ),
      new AutomationRule(
        'rule-night-light',
        '夜间有人时开启柔光',
        [
          new RuleCondition(MetricField.ILLUMINANCE, ComparisonOperator.LT, 80),
          new RuleCondition(MetricField.OCCUPIED, ComparisonOperator.GTE, 1)
        ],
        new DeviceAction(DeviceKind.LIGHT, 35),
        4,
        true
      ),
      new AutomationRule(
        'rule-humidity',
        '湿度偏高时开启通风',
        [
          new RuleCondition(MetricField.HUMIDITY, ComparisonOperator.GTE, 70)
        ],
        new DeviceAction(DeviceKind.FAN, 2),
        3,
        true
      ),
      new AutomationRule(
        'rule-day-curtain',
        '白天采光充足时拉开窗帘',
        [
          new RuleCondition(MetricField.ILLUMINANCE, ComparisonOperator.GTE, 600)
        ],
        new DeviceAction(DeviceKind.CURTAIN, 85),
        2,
        true
      ),
      new AutomationRule(
        'rule-energy-fan',
        '高温节能优先使用低档风扇',
        [
          new RuleCondition(MetricField.TEMPERATURE, ComparisonOperator.GTE, 32)
        ],
        new DeviceAction(DeviceKind.FAN, 1),
        1,
        true
      )
    ];

    let scenes: ScenePreset[] = [
      new ScenePreset(
        'scene-return',
        '回寝模式',
        '灯光 75%，窗帘半开，空调 26°C',
        new EnvironmentState(28, 62, 90, true),
        new DeviceState(75, 1, 55, 26)
      ),
      new ScenePreset(
        'scene-sleep',
        '睡眠模式',
        '夜灯 20%，窗帘关闭，风扇低档',
        new EnvironmentState(25, 55, 20, true),
        new DeviceState(20, 1, 0, 0)
      )
    ];

    return new AppState(environment, devices, rules, scenes, []);
  }

  static environmentScenarios(): MockEnvironmentScenario[] {
    return [
      new MockEnvironmentScenario(
        'mock-hot',
        '高温午间',
        '33°C / 湿度 62% / 720 lx',
        new EnvironmentState(33, 62, 720, true)
      ),
      new MockEnvironmentScenario(
        'mock-night',
        '夜间回寝',
        '25°C / 湿度 58% / 45 lx',
        new EnvironmentState(25, 58, 45, true)
      ),
      new MockEnvironmentScenario(
        'mock-humid',
        '梅雨潮湿',
        '27°C / 湿度 78% / 210 lx',
        new EnvironmentState(27, 78, 210, true)
      ),
      new MockEnvironmentScenario(
        'mock-empty',
        '人离寝',
        '26°C / 湿度 52% / 480 lx',
        new EnvironmentState(26, 52, 480, false)
      )
    ];
  }
}
