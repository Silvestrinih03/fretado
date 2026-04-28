enum UserTypeEnum { driver, client }

extension RegisterAccountTypeApiMapper on UserTypeEnum {
  int get userTypeId {
    switch (this) {
      case UserTypeEnum.client:
        return 1;
      case UserTypeEnum.driver:
        return 2;
    }
  }
}
