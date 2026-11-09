# 联动实验室 智能宿舍自动化规则编排 App

本项目是《鸿蒙高级应用开发工程师认证》期末大作业，选题为“联动实验室——智能宿舍自动化规则编排 App”。应用使用 ArkTS、ArkUI、Preferences、emitter 和 Hypium 实现规则编排、设备联动、场景演练、执行日志与数据恢复，不依赖真实硬件或云平台。

## 功能

- 4 类模拟设备：主灯、通风扇、智能窗帘、空调。
- 4 种 Mock 环境：高温午间、夜间回寝、梅雨潮湿、人离寝。
- 环境数据：温度、湿度、照度和房间有人状态。
- 新增、编辑、删除、启停规则，支持单条件和双条件。
- 5 条默认规则，包含双条件判断、规则优先级和同设备冲突处理。
- 2 个默认场景，并支持保存当前环境和设备状态。
- 记录触发条件、动作顺序、冲突覆盖和最终设备状态。
- 使用 Preferences 持久化设备、规则、场景和执行记录。
- 使用 emitter 在规则执行后发送状态更新事件。
- 8 条 Hypium 单元测试，覆盖正常、边界、异常和冲突。

## 开发环境

```text
DevEco Studio: 5.0.13
HarmonyOS SDK: 5.0.5
API Version: 17
Compatible SDK: 5.0.0(12)
测试框架: @ohos/hypium 1.0.18
```

## 运行方法

1. 使用 DevEco Studio 打开项目根目录。
2. 等待 `ohpm install` 完成。
3. 在 Device Manager 中启动 HarmonyOS 手机模拟器。
4. 选择 `entry` 模块和模拟器，点击 Run。
5. 选择 Mock 场景修改环境数据。
6. 点击“立即演练”执行启用规则。
7. 滚动到“执行记录”查看条件、执行顺序和冲突结果。

## 单元测试

在项目根目录执行：

```powershell
$env:DEVECO_SDK_HOME='C:\Program Files\Huawei\DevEco Studio\sdk'
$env:PATH='C:\Program Files\Huawei\DevEco Studio\jbr\bin;' + $env:PATH

& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' test `
  --mode module `
  -p product=default `
  -p module=entry@default `
  -p buildMode=debug `
  --no-daemon
```

当前测试结果：

```text
Tests run: 8, Failure: 0, Error: 0, Pass: 8, Ignore: 0
```

## 核心目录

```text
entry/src/main/ets/model/Domain.ets
entry/src/main/ets/model/MockData.ets
entry/src/main/ets/service/RuleEngine.ets
entry/src/main/ets/service/PersistenceService.ets
entry/src/main/ets/service/RuleEventBus.ets
entry/src/main/ets/pages/Index.ets
entry/src/test/RuleEngine.test.ets
```

## 截图

运行截图、冲突记录、持久化恢复和单元测试截图位于 `report-assets/`。

## 作者

```text
姓名：候景景
学号：20230313138
班级：23物联1
GitHub 账号：houjingjing111
```
