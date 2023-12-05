@isTest
private with sharing class ProductLicenseManagement_Test {
    public ProductLicenseManagement_Test() {

    }
    @isTest
    static void testGetActiveLicense() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('CalloutRes');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        // call the method that performs the callout
        String activeLicense = ProductLicenseManagement.getActiveLicense();
        ProductLicenseManagement.productLicenseResponseClass result = new ProductLicenseManagement.productLicenseResponseClass();
        result.expirationDate = system.today();
        result.status = 'Active';
        result.licenseExpiredNotificationdDate = 1;
        result.licenseId = '321654';
        result.licenseName = 'L0001';
        result.totalLicenses = 1;
        result.usedLicenses = 1;
        result.message = 'Active License';
        Boolean isValid = ProductLicenseManagement.isLicenseValid(ProductLicenseManagement.getActiveLicense());
    }

}