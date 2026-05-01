enum UserTypeEnum { driver, client }

extension RegisterAccountTypeApiMapper on UserTypeEnum {
  static UserTypeEnum fromUserTypeId(int userTypeId) {
    if (userTypeId == UserTypeEnum.driver.userTypeId) {
      return UserTypeEnum.driver;
    }

    return UserTypeEnum.client;
  }

  int get userTypeId {
    switch (this) {
      case UserTypeEnum.client:
        return 1;
      case UserTypeEnum.driver:
        return 2;
    }
  }

  String get displayName {
    switch (this) {
      case UserTypeEnum.client:
        return 'Cliente';
      case UserTypeEnum.driver:
        return 'Motorista';
    }
  }
}
