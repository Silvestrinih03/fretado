enum RegisterAccountType { driver, client }

extension RegisterAccountTypeApiMapper on RegisterAccountType {
  int get userTypeId {
    switch (this) {
      case RegisterAccountType.client:
        return 1;
      case RegisterAccountType.driver:
        return 2;
    }
  }
}
