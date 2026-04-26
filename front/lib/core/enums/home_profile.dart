enum HomeProfile { driver, client }

extension HomeProfileMapper on HomeProfile {
  static HomeProfile fromUserTypeId(int userTypeId) {
    if (userTypeId == 2) {
      return HomeProfile.driver;
    }
    return HomeProfile.client;
  }
}
