import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import {
  AppState,
  AutomationRule,
  ComparisonOperator,
  DeviceAction,
  DeviceKind,
  EvaluationResult,
  ExecutionRecord,
  MetricField,
  MockEnvironmentScenario,
  RuleCondition,
  ScenePreset
} from '../model/Domain';
import { MockData } from '../model/MockData';
import { PersistenceService } from '../service/PersistenceService';
import { RuleEngine } from '../service/RuleEngine';
import { RuleEventBus } from '../service/RuleEventBus';

@Entry
@Component
struct Index {
  @State private state: AppState = MockData.createDefaultState();
  @State private scenarios: MockEnvironmentScenario[] = MockData.environmentScenarios();
  @State private temperature: number = 27;
  @State private humidity: number = 64;
  @State private illuminance: number = 520;
  @State private occupied: boolean = true;
  @State private lightLevel: number = 45;
  @State private fanLevel: number = 1;
  @State private curtainPosition: number = 35;
  @State private airConditionerTarget: number = 26;
  @State private selectedMock: string = '自定义状态';
  @State private ready: boolean = false;
  @State private eventTick: number = 0;
  @State private editingRuleId: string = '';
  @State private ruleName: string = '';
  @State private condition1Field: MetricField = MetricField.TEMPERATURE;
  @State private condition1Operator: ComparisonOperator = ComparisonOperator.GTE;
  @State private condition1Value: string = '28';
  @State private useSecondCondition: boolean = false;
  @State private condition2Field: MetricField = MetricField.OCCUPIED;
  @State private condition2Operator: ComparisonOperator = ComparisonOperator.GTE;
  @State private condition2Value: string = '1';
  @State private actionDevice: DeviceKind = DeviceKind.AIR_CONDITIONER;
  @State private actionValue: string = '24';
  @State private priorityText: string = '3';

  private persistence: PersistenceService = new PersistenceService();
  private ruleEventListener: () => void = () => {};
  private metricOptions: SelectOption[] = [
    { value: '温度' },
    { value: '湿度' },
    { value: '照度' },
    { value: '有人状态' }
  ];
  private operatorOptions: SelectOption[] = [
    { value: '大于 >' },
    { value: '大于等于 >=' },
    { value: '小于 <' },
    { value: '小于等于 <=' }
  ];
  private deviceOptions: SelectOption[] = [
    { value: '灯光' },
    { value: '风扇' },
    { value: '窗帘' },
    { value: '空调' }
  ];

  aboutToAppear(): void {
    this.ruleEventListener = (): void => {
      this.eventTick += 1;
    };
    RuleEventBus.subscribe(this.ruleEventListener);
    this.loadState();
  }

  aboutToDisappear(): void {
    RuleEventBus.unsubscribe(this.ruleEventListener);
  }

  private async loadState(): Promise<void> {
    let loaded: AppState | null = await this.persistence.load(this.getUiContext());
    if (loaded !== null) {
      this.state = loaded;
      this.syncVisibleState();
      promptAction.showToast({ message: '已恢复上次设备、规则和记录' });
    }
    this.ready = true;
  }

  private getUiContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private persist(): void {
    this.persistence.save(this.getUiContext(), this.state);
  }

  private syncVisibleState(): void {
    this.temperature = this.state.environment.temperature;
    this.humidity = this.state.environment.humidity;
    this.illuminance = this.state.environment.illuminance;
    this.occupied = this.state.environment.occupied;
    this.lightLevel = this.state.devices.lightLevel;
    this.fanLevel = this.state.devices.fanLevel;
    this.curtainPosition = this.state.devices.curtainPosition;
    this.airConditionerTarget = this.state.devices.airConditionerTarget;
  }

  private setEnvironmentValues(temperature: number, humidity: number, illuminance: number,
    occupied: boolean): void {
    this.temperature = temperature;
    this.humidity = humidity;
    this.illuminance = illuminance;
    this.occupied = occupied;
    this.state.environment.temperature = temperature;
    this.state.environment.humidity = humidity;
    this.state.environment.illuminance = illuminance;
    this.state.environment.occupied = occupied;
  }

  private setTemperature(value: number): void {
    let rounded: number = Math.round(value);
    this.temperature = rounded;
    this.selectedMock = '自定义状态';
    this.state.environment.temperature = rounded;
    this.state = this.state.clone();
    this.persist();
  }

  private setHumidity(value: number): void {
    let rounded: number = Math.round(value);
    this.humidity = rounded;
    this.selectedMock = '自定义状态';
    this.state.environment.humidity = rounded;
    this.state = this.state.clone();
    this.persist();
  }

  private setIlluminance(value: number): void {
    let rounded: number = Math.round(value);
    this.illuminance = rounded;
    this.selectedMock = '自定义状态';
    this.state.environment.illuminance = rounded;
    this.state = this.state.clone();
    this.persist();
  }

  private setOccupied(value: boolean): void {
    this.occupied = value;
    this.selectedMock = '自定义状态';
    this.state.environment.occupied = value;
    this.state = this.state.clone();
    this.persist();
  }

  private setLight(value: number): void {
    this.state.devices.lightLevel = RuleEngine.clamp(Math.round(value), 0, 100);
    this.state = this.state.clone();
    this.syncVisibleState();
    this.persist();
  }

  private setFan(value: number): void {
    this.state.devices.fanLevel = RuleEngine.clamp(Math.round(value), 0, 3);
    this.state = this.state.clone();
    this.syncVisibleState();
    this.persist();
  }

  private setCurtain(value: number): void {
    this.state.devices.curtainPosition = RuleEngine.clamp(Math.round(value), 0, 100);
    this.state = this.state.clone();
    this.syncVisibleState();
    this.persist();
  }

  private setAirConditioner(value: number): void {
    let rounded: number = Math.round(value);
    this.state.devices.airConditionerTarget = rounded < 16 ? 0 : RuleEngine.clamp(rounded, 16, 30);
    this.state = this.state.clone();
    this.syncVisibleState();
    this.persist();
  }

  private evaluateRules(source: string): void {
    let result: EvaluationResult = RuleEngine.evaluate(this.state, source);
    this.state = this.state.clone();
    this.lightLevel = this.state.devices.lightLevel;
    this.fanLevel = this.state.devices.fanLevel;
    this.curtainPosition = this.state.devices.curtainPosition;
    this.airConditionerTarget = this.state.devices.airConditionerTarget;
    this.persist();
    RuleEventBus.publish();
    let message: string = result.matchedCount === 0
      ? '规则已检查，本次没有命中'
      : `命中 ${result.matchedCount} 条，执行 ${result.executedCount} 个动作`;
    if (result.skippedCount > 0) {
      message += `，处理 ${result.skippedCount} 个冲突`;
    }
    promptAction.showToast({ message: message });
  }

  private applyMockScenario(scenario: MockEnvironmentScenario): void {
    this.selectedMock = scenario.name;
    if (scenario.name === '高温午间') {
      this.setEnvironmentValues(33, 62, 720, true);
    } else if (scenario.name === '夜间回寝') {
      this.setEnvironmentValues(25, 58, 45, true);
    } else if (scenario.name === '梅雨潮湿') {
      this.setEnvironmentValues(27, 78, 210, true);
    } else if (scenario.name === '人离寝') {
      this.setEnvironmentValues(26, 52, 480, false);
    }
    this.state = this.state.clone();
    this.persist();
    promptAction.showToast({ message: `已载入：${scenario.name}` });
  }

  private runScene(scene: ScenePreset): void {
    this.selectedMock = `场景：${scene.name}`;
    this.state.environment = scene.environment.clone();
    this.state.devices = scene.devices.clone();
    this.syncVisibleState();
    this.state = this.state.clone();
    this.persist();
    promptAction.showToast({ message: `已载入场景：${scene.name}` });
  }

  private saveCurrentScene(): void {
    let sceneNumber: number = this.state.scenes.length + 1;
    let scene: ScenePreset = new ScenePreset(
      `scene-user-${Date.now()}`,
      `我的场景 ${sceneNumber}`,
      this.state.devices.summary(),
      this.state.environment.clone(),
      this.state.devices.clone()
    );
    this.state.scenes = this.state.scenes.concat([scene]);
    if (this.state.scenes.length > 5) {
      this.state.scenes = this.state.scenes.slice(this.state.scenes.length - 5);
    }
    this.state = this.state.clone();
    this.persist();
    promptAction.showToast({ message: '已保存当前环境与设备状态' });
  }

  private beginAddRule(): void {
    this.editingRuleId = 'new';
    this.ruleName = `自定义规则 ${this.state.rules.length + 1}`;
    this.condition1Field = MetricField.TEMPERATURE;
    this.condition1Operator = ComparisonOperator.GTE;
    this.condition1Value = '28';
    this.useSecondCondition = true;
    this.condition2Field = MetricField.OCCUPIED;
    this.condition2Operator = ComparisonOperator.GTE;
    this.condition2Value = '1';
    this.actionDevice = DeviceKind.AIR_CONDITIONER;
    this.actionValue = '24';
    this.priorityText = '3';
  }

  private beginEditRule(rule: AutomationRule): void {
    this.editingRuleId = rule.id;
    this.ruleName = rule.name;
    this.condition1Field = rule.conditions[0].field;
    this.condition1Operator = rule.conditions[0].operator;
    this.condition1Value = `${rule.conditions[0].value}`;
    this.useSecondCondition = rule.conditions.length > 1;
    if (rule.conditions.length > 1) {
      this.condition2Field = rule.conditions[1].field;
      this.condition2Operator = rule.conditions[1].operator;
      this.condition2Value = `${rule.conditions[1].value}`;
    } else {
      this.condition2Field = MetricField.OCCUPIED;
      this.condition2Operator = ComparisonOperator.GTE;
      this.condition2Value = '1';
    }
    this.actionDevice = rule.action.device;
    this.actionValue = `${rule.action.value}`;
    this.priorityText = `${rule.priority}`;
  }

  private saveRule(): void {
    let firstValue: number = Number(this.condition1Value);
    let secondValue: number = Number(this.condition2Value);
    let actionNumber: number = Number(this.actionValue);
    let priority: number = Number(this.priorityText);
    if (firstValue !== firstValue || actionNumber !== actionNumber || priority !== priority ||
      (this.useSecondCondition && secondValue !== secondValue)) {
      promptAction.showToast({ message: '请输入有效数字' });
      return;
    }

    let conditions: RuleCondition[] = [
      new RuleCondition(this.condition1Field, this.condition1Operator, firstValue)
    ];
    if (this.useSecondCondition) {
      conditions.push(new RuleCondition(this.condition2Field, this.condition2Operator, secondValue));
    }
    let safePriority: number = RuleEngine.clamp(Math.round(priority), 1, 5);
    let name: string = this.ruleName.trim().length > 0 ? this.ruleName.trim() : '未命名规则';

    if (this.editingRuleId === 'new') {
      let rule: AutomationRule = new AutomationRule(
        `rule-${Date.now()}`,
        name,
        conditions,
        new DeviceAction(this.actionDevice, actionNumber),
        safePriority,
        true,
        Date.now()
      );
      this.state.rules = this.state.rules.concat([rule]);
    } else {
      let updatedRules: AutomationRule[] = [];
      for (let index: number = 0; index < this.state.rules.length; index++) {
        let current: AutomationRule = this.state.rules[index];
        if (current.id === this.editingRuleId) {
          updatedRules.push(new AutomationRule(
            current.id,
            name,
            conditions,
            new DeviceAction(this.actionDevice, actionNumber),
            safePriority,
            current.enabled,
            current.createdAt
          ));
        } else {
          updatedRules.push(current);
        }
      }
      this.state.rules = updatedRules;
    }
    this.state = this.state.clone();
    this.editingRuleId = '';
    this.persist();
    promptAction.showToast({ message: '规则已保存' });
  }

  private toggleRule(ruleId: string, enabled: boolean): void {
    let updatedRules: AutomationRule[] = [];
    for (let index: number = 0; index < this.state.rules.length; index++) {
      let current: AutomationRule = this.state.rules[index];
      if (current.id === ruleId) {
        current.enabled = enabled;
      }
      updatedRules.push(current);
    }
    this.state.rules = updatedRules;
    this.state = this.state.clone();
    this.persist();
  }

  private deleteRule(ruleId: string): void {
    let keptRules: AutomationRule[] = [];
    for (let index: number = 0; index < this.state.rules.length; index++) {
      if (this.state.rules[index].id !== ruleId) {
        keptRules.push(this.state.rules[index]);
      }
    }
    this.state.rules = keptRules;
    this.state = this.state.clone();
    this.persist();
    promptAction.showToast({ message: '规则已删除' });
  }

  private clearLogs(): void {
    this.state.logs = [];
    this.state.lastRunAt = '尚未运行';
    this.state = this.state.clone();
    this.persist();
  }

  private metricFieldAt(index: number): MetricField {
    if (index === 0) {
      return MetricField.TEMPERATURE;
    }
    if (index === 1) {
      return MetricField.HUMIDITY;
    }
    if (index === 2) {
      return MetricField.ILLUMINANCE;
    }
    return MetricField.OCCUPIED;
  }

  private operatorAt(index: number): ComparisonOperator {
    if (index === 0) {
      return ComparisonOperator.GT;
    }
    if (index === 1) {
      return ComparisonOperator.GTE;
    }
    if (index === 2) {
      return ComparisonOperator.LT;
    }
    return ComparisonOperator.LTE;
  }

  private deviceAt(index: number): DeviceKind {
    if (index === 0) {
      return DeviceKind.LIGHT;
    }
    if (index === 1) {
      return DeviceKind.FAN;
    }
    if (index === 2) {
      return DeviceKind.CURTAIN;
    }
    return DeviceKind.AIR_CONDITIONER;
  }

  private metricIndex(field: MetricField): number {
    if (field === MetricField.TEMPERATURE) {
      return 0;
    }
    if (field === MetricField.HUMIDITY) {
      return 1;
    }
    if (field === MetricField.ILLUMINANCE) {
      return 2;
    }
    return 3;
  }

  private operatorIndex(operator: ComparisonOperator): number {
    if (operator === ComparisonOperator.GT) {
      return 0;
    }
    if (operator === ComparisonOperator.GTE) {
      return 1;
    }
    if (operator === ComparisonOperator.LT) {
      return 2;
    }
    return 3;
  }

  private deviceIndex(device: DeviceKind): number {
    if (device === DeviceKind.LIGHT) {
      return 0;
    }
    if (device === DeviceKind.FAN) {
      return 1;
    }
    if (device === DeviceKind.CURTAIN) {
      return 2;
    }
    return 3;
  }

  @Builder
  private SectionHeading(title: string, subtitle: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17324D')
      Text(subtitle)
        .fontSize(12)
        .fontColor('#697977')
        .lineHeight(18)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private TemperatureControl() {
    Column({ space: 8 }) {
      Row() {
        Text('温度')
          .fontSize(14)
          .fontColor('#354847')
        Blank()
        Text(`${this.temperature}°C`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B806F')
      }
      .width('100%')
      Row({ space: 8 }) {
        Button('−')
          .width(34)
          .height(32)
          .fontSize(18)
          .fontColor('#2B806F')
          .backgroundColor('#E7F1EE')
          .borderRadius(10)
          .onClick(() => {
            let nextValue: number = this.temperature - 1;
            if (nextValue < -10) {
              nextValue = -10;
            }
            this.setTemperature(nextValue);
          })
        Slider({
          value: this.temperature,
          min: -10,
          max: 45,
          step: 1,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .selectedColor('#2B806F')
          .trackColor('#DDE7E3')
          .blockColor('#FFFFFF')
          .onChange((changedValue: number) => {
            this.setTemperature(changedValue);
          })
        Button('+')
          .width(34)
          .height(32)
          .fontSize(18)
          .fontColor('#2B806F')
          .backgroundColor('#E7F1EE')
          .borderRadius(10)
          .onClick(() => {
            let nextValue: number = this.temperature + 1;
            if (nextValue > 45) {
              nextValue = 45;
            }
            this.setTemperature(nextValue);
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private HumidityControl() {
    Column({ space: 8 }) {
      Row() {
        Text('湿度')
          .fontSize(14)
          .fontColor('#354847')
        Blank()
        Text(`${this.humidity}%`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B806F')
      }
      .width('100%')
      Row({ space: 8 }) {
        Button('−')
          .width(34)
          .height(32)
          .fontSize(18)
          .fontColor('#2B806F')
          .backgroundColor('#E7F1EE')
          .borderRadius(10)
          .onClick(() => {
            let nextValue: number = this.humidity - 1;
            if (nextValue < 20) {
              nextValue = 20;
            }
            this.setHumidity(nextValue);
          })
        Slider({
          value: this.humidity,
          min: 20,
          max: 90,
          step: 1,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .selectedColor('#2B806F')
          .trackColor('#DDE7E3')
          .blockColor('#FFFFFF')
          .onChange((changedValue: number) => {
            this.setHumidity(changedValue);
          })
        Button('+')
          .width(34)
          .height(32)
          .fontSize(18)
          .fontColor('#2B806F')
          .backgroundColor('#E7F1EE')
          .borderRadius(10)
          .onClick(() => {
            let nextValue: number = this.humidity + 1;
            if (nextValue > 90) {
              nextValue = 90;
            }
            this.setHumidity(nextValue);
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private IlluminanceControl() {
    Column({ space: 8 }) {
      Row() {
        Text('照度')
          .fontSize(14)
          .fontColor('#354847')
        Blank()
        Text(`${this.illuminance} lx`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B806F')
      }
      .width('100%')
      Row({ space: 8 }) {
        Button('−')
          .width(34)
          .height(32)
          .fontSize(18)
          .fontColor('#2B806F')
          .backgroundColor('#E7F1EE')
          .borderRadius(10)
          .onClick(() => {
            let nextValue: number = this.illuminance - 10;
            if (nextValue < 0) {
              nextValue = 0;
            }
            this.setIlluminance(nextValue);
          })
        Slider({
          value: this.illuminance,
          min: 0,
          max: 1200,
          step: 10,
          style: SliderStyle.OutSet
        })
          .layoutWeight(1)
          .selectedColor('#2B806F')
          .trackColor('#DDE7E3')
          .blockColor('#FFFFFF')
          .onChange((changedValue: number) => {
            this.setIlluminance(changedValue);
          })
        Button('+')
          .width(34)
          .height(32)
          .fontSize(18)
          .fontColor('#2B806F')
          .backgroundColor('#E7F1EE')
          .borderRadius(10)
          .onClick(() => {
            let nextValue: number = this.illuminance + 10;
            if (nextValue > 1200) {
              nextValue = 1200;
            }
            this.setIlluminance(nextValue);
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private ScenarioButton(scenario: MockEnvironmentScenario) {
    Column({ space: 3 }) {
      Text(scenario.name)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#17324D')
      Text(scenario.description)
        .fontSize(10)
        .fontColor('#6A7977')
    }
    .layoutWeight(1)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 8, right: 8 })
    .backgroundColor('#EEF4F1')
    .borderRadius(14)
    .onClick(() => {
      this.applyMockScenario(scenario);
    })
  }

  @Builder
  private LightDeviceCard() {
    Column({ space: 10 }) {
      Row() {
        Text('主灯')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17324D')
        Blank()
        Text(this.lightLevel > 0 ? '开启' : '关闭')
          .fontSize(11)
          .fontColor(this.lightLevel > 0 ? '#2B806F' : '#7A8887')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.lightLevel > 0 ? '#E4F4EF' : '#EEF0EF')
          .borderRadius(10)
      }
      .width('100%')
      Text(`${this.lightLevel}% 亮度`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17324D')
      Slider({
        value: this.lightLevel,
        min: 0,
        max: 100,
        step: 5,
        style: SliderStyle.OutSet
      })
        .selectedColor('#F0B45A')
        .trackColor('#ECE9E1')
        .onChange((value: number) => {
          this.setLight(value);
        })
    }
    .layoutWeight(1)
    .height(178)
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
  }

  @Builder
  private FanDeviceCard() {
    Column({ space: 10 }) {
      Row() {
        Text('通风扇')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17324D')
        Blank()
        Text(this.fanLevel > 0 ? `${this.fanLevel} 档` : '关闭')
          .fontSize(11)
          .fontColor(this.fanLevel > 0 ? '#2B806F' : '#7A8887')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.fanLevel > 0 ? '#E4F4EF' : '#EEF0EF')
          .borderRadius(10)
      }
      .width('100%')
      Text('按档位调节风速')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17324D')
      Slider({
        value: this.fanLevel,
        min: 0,
        max: 3,
        step: 1,
        style: SliderStyle.OutSet
      })
        .selectedColor('#5AA99A')
        .trackColor('#DDEBE7')
        .onChange((value: number) => {
          this.setFan(value);
        })
    }
    .layoutWeight(1)
    .height(178)
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
  }

  @Builder
  private CurtainDeviceCard() {
    Column({ space: 10 }) {
      Row() {
        Text('智能窗帘')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17324D')
        Blank()
        Text(this.curtainPosition === 0 ? '全闭' : '可调')
          .fontSize(11)
          .fontColor('#7A8887')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#EEF0EF')
          .borderRadius(10)
      }
      .width('100%')
      Text(`开启 ${this.curtainPosition}%`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17324D')
      Slider({
        value: this.curtainPosition,
        min: 0,
        max: 100,
        step: 5,
        style: SliderStyle.OutSet
      })
        .selectedColor('#7EA6A0')
        .trackColor('#DDE7E3')
        .onChange((value: number) => {
          this.setCurtain(value);
        })
    }
    .layoutWeight(1)
    .height(178)
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
  }

  @Builder
  private AirConditionerDeviceCard() {
    Column({ space: 10 }) {
      Row() {
        Text('空调')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17324D')
        Blank()
        Text(this.airConditionerTarget > 0 ? '制冷' : '关闭')
          .fontSize(11)
          .fontColor(this.airConditionerTarget > 0 ? '#2B806F' : '#7A8887')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.airConditionerTarget > 0 ? '#E4F4EF' : '#EEF0EF')
          .borderRadius(10)
      }
      .width('100%')
      Text(this.airConditionerTarget > 0
        ? `${this.airConditionerTarget}°C`
        : '已关闭')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17324D')
      Slider({
        value: this.airConditionerTarget,
        min: 0,
        max: 30,
        step: 1,
        style: SliderStyle.OutSet
      })
        .selectedColor('#4A9D8E')
        .trackColor('#DDE7E3')
        .onChange((value: number) => {
          this.setAirConditioner(value);
        })
      Text('拖到最左侧关闭')
        .fontSize(10)
        .fontColor('#7A8887')
    }
    .layoutWeight(1)
    .height(178)
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
  }

  @Builder
  private RuleEditor() {
    Column({ space: 12 }) {
      Row() {
        Text(this.editingRuleId === 'new' ? '新建联动规则' : '编辑联动规则')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17324D')
        Blank()
        Button('关闭')
          .fontSize(12)
          .fontColor('#526765')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.editingRuleId = '';
          })
      }
      .width('100%')

      TextInput({ text: this.ruleName, placeholder: '规则名称' })
        .height(44)
        .backgroundColor('#F3F7F5')
        .borderRadius(12)
        .onChange((value: string) => {
          this.ruleName = value;
        })

      Text('条件 1')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#526765')
      Row({ space: 8 }) {
        Select(this.metricOptions)
          .selected(this.metricIndex(this.condition1Field))
          .value(this.metricOptions[this.metricIndex(this.condition1Field)].value)
          .layoutWeight(1)
          .onSelect((index: number) => {
            this.condition1Field = this.metricFieldAt(index);
          })
        Select(this.operatorOptions)
          .selected(this.operatorIndex(this.condition1Operator))
          .value(this.operatorOptions[this.operatorIndex(this.condition1Operator)].value)
          .layoutWeight(1)
          .onSelect((index: number) => {
            this.condition1Operator = this.operatorAt(index);
          })
        TextInput({ text: this.condition1Value, placeholder: '数值' })
          .type(InputType.Number)
          .width(74)
          .height(42)
          .backgroundColor('#F3F7F5')
          .borderRadius(10)
          .onChange((value: string) => {
            this.condition1Value = value;
          })
      }
      .width('100%')

      Row() {
        Text('增加第二个条件')
          .fontSize(14)
          .fontColor('#354847')
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.useSecondCondition })
          .selectedColor('#2B806F')
          .onChange((isOn: boolean) => {
            this.useSecondCondition = isOn;
          })
      }
      .width('100%')

      if (this.useSecondCondition) {
        Text('条件 2（两个条件同时满足才触发）')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#526765')
        Row({ space: 8 }) {
          Select(this.metricOptions)
            .selected(this.metricIndex(this.condition2Field))
            .value(this.metricOptions[this.metricIndex(this.condition2Field)].value)
            .layoutWeight(1)
            .onSelect((index: number) => {
              this.condition2Field = this.metricFieldAt(index);
            })
          Select(this.operatorOptions)
            .selected(this.operatorIndex(this.condition2Operator))
            .value(this.operatorOptions[this.operatorIndex(this.condition2Operator)].value)
            .layoutWeight(1)
            .onSelect((index: number) => {
              this.condition2Operator = this.operatorAt(index);
            })
          TextInput({ text: this.condition2Value, placeholder: '数值' })
            .type(InputType.Number)
            .width(74)
            .height(42)
            .backgroundColor('#F3F7F5')
            .borderRadius(10)
            .onChange((value: string) => {
              this.condition2Value = value;
            })
        }
        .width('100%')
      }

      Divider()
        .color('#E1E9E6')
        .margin({ top: 2, bottom: 2 })
      Text('执行动作')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#526765')
      Row({ space: 8 }) {
        Select(this.deviceOptions)
          .selected(this.deviceIndex(this.actionDevice))
          .value(this.deviceOptions[this.deviceIndex(this.actionDevice)].value)
          .layoutWeight(1)
          .onSelect((index: number) => {
            this.actionDevice = this.deviceAt(index);
          })
        TextInput({ text: this.actionValue, placeholder: '目标值' })
          .type(InputType.Number)
          .width(96)
          .height(42)
          .backgroundColor('#F3F7F5')
          .borderRadius(10)
          .onChange((value: string) => {
            this.actionValue = value;
          })
        TextInput({ text: this.priorityText, placeholder: '优先级' })
          .type(InputType.Number)
          .width(68)
          .height(42)
          .backgroundColor('#F3F7F5')
          .borderRadius(10)
          .onChange((value: string) => {
            this.priorityText = value;
          })
      }
      .width('100%')
      Text('灯光 0-100，风扇 0-3，窗帘 0-100，空调 0 或 16-30；优先级 1-5。')
        .fontSize(10)
        .fontColor('#6D7D7B')
        .lineHeight(16)
      Button('保存规则')
        .width('100%')
        .height(42)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor('#17324D')
        .borderRadius(13)
        .onClick(() => {
          this.saveRule();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .border({ width: 1, color: '#E2EBE7' })
  }

  @Builder
  private RuleCard(rule: AutomationRule) {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 3 }) {
          Text(rule.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#17324D')
          Text(`优先级 ${rule.priority}`)
            .fontSize(11)
            .fontColor(rule.priority >= 4 ? '#B26A26' : '#6E7F7C')
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: rule.enabled })
          .selectedColor('#2B806F')
          .onChange((isOn: boolean) => {
            this.toggleRule(rule.id, isOn);
          })
      }
      .width('100%')
      Row({ space: 6 }) {
        Text('如果')
          .fontSize(11)
          .fontColor('#FFFFFF')
          .padding({ left: 7, right: 7, top: 3, bottom: 3 })
          .backgroundColor('#5E8F85')
          .borderRadius(8)
        Text(RuleEngine.describeConditions(rule.conditions))
          .fontSize(13)
          .fontColor('#354847')
          .layoutWeight(1)
      }
      .width('100%')
      Row({ space: 6 }) {
        Text('则')
          .fontSize(11)
          .fontColor('#17324D')
          .padding({ left: 7, right: 7, top: 3, bottom: 3 })
          .backgroundColor('#F5D9A8')
          .borderRadius(8)
        Text(RuleEngine.actionDescription(rule.action))
          .fontSize(13)
          .fontColor('#354847')
          .layoutWeight(1)
      }
      .width('100%')
      Row({ space: 10 }) {
        Button('编辑')
          .height(30)
          .fontSize(12)
          .fontColor('#2B6F63')
          .backgroundColor('#E7F1EE')
          .borderRadius(10)
          .onClick(() => {
            this.beginEditRule(rule);
          })
        Button('删除')
          .height(30)
          .fontSize(12)
          .fontColor('#A64F4F')
          .backgroundColor('#F7ECEC')
          .borderRadius(10)
          .onClick(() => {
            this.deleteRule(rule.id);
          })
        Blank()
        Text(rule.enabled ? '参与演练' : '已停用')
          .fontSize(10)
          .fontColor(rule.enabled ? '#2B806F' : '#8A9694')
      }
      .width('100%')
    }
    .width('100%')
    .padding(15)
    .backgroundColor(rule.enabled ? '#FFFFFF' : '#F2F4F3')
    .borderRadius(17)
    .border({ width: 1, color: rule.enabled ? '#DFE9E5' : '#E7EAE9' })
  }

  @Builder
  private SceneCard(scene: ScenePreset) {
    Column({ space: 8 }) {
      Row() {
        Text(scene.name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#17324D')
        Blank()
        Text('演练')
          .fontSize(11)
          .fontColor('#2B806F')
      }
      .width('100%')
      Text(scene.description)
        .fontSize(11)
        .fontColor('#657775')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(17)
      Text(`${scene.environment.temperature}°C · 湿度 ${scene.environment.humidity}% · ${scene.environment.illuminance} lx`)
        .fontSize(10)
        .fontColor('#7B8987')
    }
    .width(210)
    .height(118)
    .padding(14)
    .backgroundColor('#F8FAF9')
    .borderRadius(15)
    .border({ width: 1, color: '#DEE8E4' })
    .margin({ right: 10 })
    .onClick(() => {
      this.runScene(scene);
    })
  }

  @Builder
  private LogCard(record: ExecutionRecord) {
    Column({ space: 7 }) {
      Row() {
        Text(record.source)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#17324D')
        Blank()
        Text(record.timeLabel)
          .fontSize(10)
          .fontColor('#7A8987')
      }
      .width('100%')
      Text(record.conditionSummary)
        .fontSize(11)
        .fontColor('#5B706D')
        .lineHeight(17)
      if (record.executedActions.length > 0) {
        ForEach(record.executedActions, (action: string) => {
          Text(action)
            .fontSize(11)
            .fontColor('#276D61')
            .lineHeight(17)
        })
      }
      if (record.skippedActions.length > 0) {
        ForEach(record.skippedActions, (action: string) => {
          Text(`冲突：${action}`)
            .fontSize(11)
            .fontColor('#A8692C')
            .lineHeight(17)
        })
      }
      Text(`最终设备：${record.deviceSummary}`)
        .fontSize(10)
        .fontColor('#6D7D7B')
        .lineHeight(16)
    }
    .width('100%')
    .padding(13)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#E2EAE7' })
  }

  build() {
    if (!this.ready) {
      Column({ space: 14 }) {
        LoadingProgress()
          .width(42)
          .height(42)
          .color('#2B806F')
        Text('正在恢复规则和设备状态')
          .fontSize(14)
          .fontColor('#526765')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F3F6F4')
    } else {
      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 14 }) {
            Row() {
              Column({ space: 3 }) {
                Text('联动实验室')
                  .fontSize(30)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('智能宿舍自动化规则编排')
                  .fontSize(13)
                  .fontColor('#B9D3CD')
              }
              .alignItems(HorizontalAlign.Start)
              Blank()
              Column({ space: 4 }) {
                Text('RULE ENGINE')
                  .fontSize(10)
                  .fontColor('#F5CE8D')
                Text(`通信 ${this.eventTick % 2 === 0 ? '在线' : '活跃'}`)
                  .fontSize(11)
                  .fontColor('#D7E8E4')
              }
              .alignItems(HorizontalAlign.End)
            }
            .width('100%')

            Row({ space: 10 }) {
              Column({ space: 4 }) {
                Text(`${this.state.rules.length}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('规则总数')
                  .fontSize(10)
                  .fontColor('#B8CCC8')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Column({ space: 4 }) {
                Text(`${this.state.scenes.length}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('场景方案')
                  .fontSize(10)
                  .fontColor('#B8CCC8')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Column({ space: 4 }) {
                Text(`${this.state.logs.length}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('执行记录')
                  .fontSize(10)
                  .fontColor('#B8CCC8')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })

            Row() {
              Text(`上次演练：${this.state.lastRunAt}`)
                .fontSize(11)
                .fontColor('#C8D9D5')
              Blank()
              Button('立即演练')
                .height(38)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#17324D')
                .backgroundColor('#F4C878')
                .borderRadius(12)
                .onClick(() => {
                  this.evaluateRules('手动演练');
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#17324D')
          .borderRadius(24)

          Column({ space: 14 }) {
            this.SectionHeading('Mock 环境', '修改模拟数据，观察规则命中、设备联动和冲突处理')
            Text(`当前模拟：${this.selectedMock}`)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2B806F')
              .width('100%')
            Row({ space: 10 }) {
              this.ScenarioButton(this.scenarios[0])
              this.ScenarioButton(this.scenarios[1])
            }
            .width('100%')
            Row({ space: 10 }) {
              this.ScenarioButton(this.scenarios[2])
              this.ScenarioButton(this.scenarios[3])
            }
            .width('100%')

            this.TemperatureControl()
            this.HumidityControl()
            this.IlluminanceControl()
            Row() {
              Text('房间是否有人')
                .fontSize(14)
                .fontColor('#354847')
              Blank()
              Text(this.occupied ? '有人' : '无人')
                .fontSize(12)
                .fontColor('#2B806F')
              Toggle({ type: ToggleType.Switch, isOn: this.occupied })
                .selectedColor('#2B806F')
                .onChange((isOn: boolean) => {
                  this.setOccupied(isOn);
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(17)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .border({ width: 1, color: '#E0EAE6' })

          Column({ space: 14 }) {
            this.SectionHeading('模拟设备', '4 类设备可手动调整，规则执行后会立即反映最终状态')
            Row({ space: 12 }) {
              this.LightDeviceCard()
              this.FanDeviceCard()
            }
            .width('100%')
            Row({ space: 12 }) {
              this.CurtainDeviceCard()
              this.AirConditionerDeviceCard()
            }
            .width('100%')
          }
          .width('100%')

          Column({ space: 14 }) {
            Row() {
              this.SectionHeading('场景方案', '保存当前环境与设备，退出后仍可继续演练')
              Blank()
              Button('保存当前')
                .height(34)
                .fontSize(12)
                .fontColor('#276D61')
                .backgroundColor('#E6F2EE')
                .borderRadius(11)
                .onClick(() => {
                  this.saveCurrentScene();
                })
            }
            .width('100%')
            Scroll() {
              Row() {
                ForEach(this.state.scenes, (scene: ScenePreset) => {
                  this.SceneCard(scene)
                }, (scene: ScenePreset) => scene.id)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
          }
          .width('100%')

          Column({ space: 14 }) {
            Row() {
              this.SectionHeading('规则编排', '优先级数值越大越先执行；同一设备冲突由高优先级规则接管')
              Blank()
              Button('新增')
                .height(34)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor('#2B806F')
                .borderRadius(11)
                .onClick(() => {
                  this.beginAddRule();
                })
            }
            .width('100%')

            if (this.editingRuleId.length > 0) {
              this.RuleEditor()
            }

            ForEach(this.state.rules, (rule: AutomationRule) => {
              this.RuleCard(rule)
            }, (rule: AutomationRule) => rule.id)
          }
          .width('100%')

          Column({ space: 14 }) {
            Row() {
              this.SectionHeading('执行记录', '记录触发条件、动作顺序、冲突覆盖和最终设备状态')
              Blank()
              Button('清空')
                .height(32)
                .fontSize(11)
                .fontColor('#7A6666')
                .backgroundColor('#F2ECEC')
                .borderRadius(10)
                .onClick(() => {
                  this.clearLogs();
                })
            }
            .width('100%')
            if (this.state.logs.length === 0) {
              Text('暂无执行记录，点击“立即演练”或选择一个 Mock 场景。')
                .fontSize(13)
                .fontColor('#73817F')
                .width('100%')
                .padding(18)
                .backgroundColor('#FFFFFF')
                .borderRadius(15)
            } else {
              ForEach(this.state.logs.slice(0, 10), (record: ExecutionRecord) => {
                this.LogCard(record)
              }, (record: ExecutionRecord) => record.id)
            }
          }
          .width('100%')

          Text('候景景 · 20230313138 · 23物联1')
            .fontSize(10)
            .fontColor('#879390')
            .margin({ top: 4, bottom: 24 })
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 14 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F3F6F4')
      .scrollBar(BarState.Off)
    }
  }
}
