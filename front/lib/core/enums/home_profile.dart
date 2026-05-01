enum HomeProfileEnum { driver, client }

extension HomeProfileMapper on HomeProfileEnum {
  static HomeProfileEnum fromUserTypeId(int userTypeId) {
    if (userTypeId == 2) {
      return HomeProfileEnum.driver;
    }
    return HomeProfileEnum.client;
  }
}
