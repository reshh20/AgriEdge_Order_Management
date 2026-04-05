@isTest
public class AgriEdgeOrderTests {

    @isTest
    static void testOrderTotalUpdater() {
        AgriEdge_Order__c order1 = new AgriEdge_Order__c(
            Payment_Status__c = 'Pending',
            Order_Status__c = 'New'
        );
        insert order1;

        AgriEdge_OrderItem__c item1 = new AgriEdge_OrderItem__c(
            Order__c = order1.Id,
            Quantity__c = 2,
            Unit_Price__c = 25
        );

        AgriEdge_OrderItem__c item2 = new AgriEdge_OrderItem__c(
            Order__c = order1.Id,
            Quantity__c = 1,
            Unit_Price__c = 30
        );

        insert new List<AgriEdge_OrderItem__c>{item1, item2};

        Test.startTest();
        OrderTotalUpdater.updateOrderTotal(new Set<Id>{order1.Id});
        Test.stopTest();
    }

    @isTest
    static void testOrderStatusUpdater() {
        AgriEdge_Order__c order = new AgriEdge_Order__c(
            Payment_Status__c = 'Pending',
            Order_Status__c = 'New'
        );
        insert order;

        Test.startTest();
        OrderStatusUpdater.updateOrderStatus(new Set<Id>{order.Id});
        Test.stopTest();
    }

    @isTest
    static void testShipmentHelper() {
        AgriEdge_Order__c order = new AgriEdge_Order__c(
            Payment_Status__c = 'Paid',
            Order_Status__c = 'Processing'
        );
        insert order;

        List<AgriEdge_Order__c> orders = new List<AgriEdge_Order__c>{order};

        Test.startTest();
        AgriEdgeOrderShipmentHelper.processOrderStatusChange(orders);
        Test.stopTest();
    }

    @isTest
    static void testTriggerFlow() {
        AgriEdge_Order__c order = new AgriEdge_Order__c(
            Payment_Status__c = 'Pending',
            Order_Status__c = 'New'
        );
        insert order;

        order.Payment_Status__c = 'Failed';
        update order;
    }

    @isTest
    static void testOrderEmailSender() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            LastName = 'Test',
            Email = 'test@example.com',
            AccountId = acc.Id
        );
        insert con;

        AgriEdge_Order__c order = new AgriEdge_Order__c(
            Customer__c = acc.Id,
            Payment_Status__c = 'Paid',
            Order_Status__c = 'Processing',
            Total_Amount__c = 100
        );
        insert order;

        Test.startTest();
        OrderEmailSender.sendOrderEmail(new Set<Id>{order.Id});
        Test.stopTest();
    }
}
