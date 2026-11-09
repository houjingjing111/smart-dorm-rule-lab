import { emitter } from '@kit.BasicServicesKit';

export const RULE_EVENT_ID: string = 'smart_dorm_rule_updated';

export class RuleEventBus {
  static publish(): void {
    emitter.emit(RULE_EVENT_ID);
  }

  static subscribe(callback: () => void): void {
    emitter.on(RULE_EVENT_ID, callback);
  }

  static unsubscribe(callback?: () => void): void {
    if (callback === undefined) {
      emitter.off(RULE_EVENT_ID);
      return;
    }
    emitter.off(RULE_EVENT_ID, callback);
  }
}
