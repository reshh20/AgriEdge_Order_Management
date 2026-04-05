public class AgriEdgeOrderShipmentHelper {

    public static void processOrderStatusChange(List<AgriEdge_Order__c> updatedOrders) {

        List<AgriEdge_Shipment__c> shipmentsToInsert = new List<AgriEdge_Shipment__c>();
        List<AgriEdge_Shipment__c> shipmentsToUpdate = new List<AgriEdge_Shipment__c>();
        List<AgriEdge_Order__c> ordersToUpdate = new List<AgriEdge_Order__c>();
        List<AgriEdge_OrderItem__c> orderItemsToDelete = new List<AgriEdge_OrderItem__c>();
        List<AgriEdge_Shipment__c> shipmentsToDelete = new List<AgriEdge_Shipment__c>();

        Set<Id> orderIds = new Set<Id>();

        for (AgriEdge_Order__c order : updatedOrders) {
            orderIds.add(order.Id);
        }

        // Existing Shipments (CORRECT - no change)
        Map<Id, AgriEdge_Shipment__c> existingShipments = new Map<Id, AgriEdge_Shipment__c>();
        for (AgriEdge_Shipment__c shipment : [
            SELECT Id, AgriEdge_Order__c, Status__c
            FROM AgriEdge_Shipment__c
            WHERE AgriEdge_Order__c IN :orderIds
        ]) {
            existingShipments.put(shipment.AgriEdge_Order__c, shipment);
        }

        // Existing Order Items (FIXED HERE ✅)
        Map<Id, List<AgriEdge_OrderItem__c>> existingOrderItems = new Map<Id, List<AgriEdge_OrderItem__c>>();
        for (AgriEdge_OrderItem__c item : [
            SELECT Id, Order__c
            FROM AgriEdge_OrderItem__c
            WHERE Order__c IN :orderIds
        ]) {
            if (!existingOrderItems.containsKey(item.Order__c)) {
                existingOrderItems.put(item.Order__c, new List<AgriEdge_OrderItem__c>());
            }
            existingOrderItems.get(item.Order__c).add(item);
        }

        // Main Logic
        for (AgriEdge_Order__c order : updatedOrders) {

            AgriEdge_Order__c updatedOrder = new AgriEdge_Order__c(Id = order.Id);

            // Payment Logic
            if (order.Payment_Status__c == 'Paid' && order.Order_Status__c != 'Delivered') {
                updatedOrder.Order_Status__c = 'Delivered';
                ordersToUpdate.add(updatedOrder);
            }
            else if (order.Payment_Status__c == 'Pending') {
                updatedOrder.Order_Status__c = 'Processing';
                ordersToUpdate.add(updatedOrder);
            }
            else if (order.Payment_Status__c == 'Failed') {
                updatedOrder.Order_Status__c = 'Canceled';
                ordersToUpdate.add(updatedOrder);

                if (existingOrderItems.containsKey(order.Id)) {
                    orderItemsToDelete.addAll(existingOrderItems.get(order.Id));
                }
                if (existingShipments.containsKey(order.Id)) {
                    shipmentsToDelete.add(existingShipments.get(order.Id));
                }
            }

            // Shipment Logic
            if (order.Order_Status__c == 'Processing' && !existingShipments.containsKey(order.Id)) {

                AgriEdge_Shipment__c shipment = new AgriEdge_Shipment__c(
                    AgriEdge_Order__c = order.Id,
                    Tracking_Number__c = 'TEST_' + order.Id,
                    Status__c = 'Pending'
                );

                shipmentsToInsert.add(shipment);
            }
            else if (order.Order_Status__c == 'Shipped' || order.Order_Status__c == 'Delivered') {

                if (existingShipments.containsKey(order.Id)) {
                    AgriEdge_Shipment__c shipment = existingShipments.get(order.Id);

                    shipment.Status__c =
                        (order.Order_Status__c == 'Shipped') ? 'In Transit' : 'Delivered';

                    shipmentsToUpdate.add(shipment);
                }
            }
        }

        // DML Operations
        if (!ordersToUpdate.isEmpty()) update ordersToUpdate;
        if (!shipmentsToInsert.isEmpty()) insert shipmentsToInsert;
        if (!shipmentsToUpdate.isEmpty()) update shipmentsToUpdate;
        if (!orderItemsToDelete.isEmpty()) delete orderItemsToDelete;
        if (!shipmentsToDelete.isEmpty()) delete shipmentsToDelete;
    }
}
