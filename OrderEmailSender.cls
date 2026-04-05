public class OrderEmailSender {

    public static void sendOrderEmail(Set<Id> orderIds) {

        if (orderIds == null || orderIds.isEmpty()) {
            return;
        }

        // Fetch Orders (Removed invalid fields)
        List<AgriEdge_Order__c> orders = [
            SELECT Id, Name, Total_Amount__c, Payment_Status__c, Order_Status__c,
                   Customer__c, CreatedDate
            FROM AgriEdge_Order__c
            WHERE Id IN :orderIds
        ];

        // Collect Customer (Account) IDs
        Set<Id> accountIds = new Set<Id>();
        for (AgriEdge_Order__c order : orders) {
            if (order.Customer__c != null) {
                accountIds.add(order.Customer__c);
            }
        }

        // Get Emails from Contacts
        Map<Id, List<String>> accountEmails = new Map<Id, List<String>>();

        for (Contact contact : [
            SELECT Email, AccountId 
            FROM Contact 
            WHERE AccountId IN :accountIds AND Email != null
        ]) {
            if (!accountEmails.containsKey(contact.AccountId)) {
                accountEmails.put(contact.AccountId, new List<String>());
            }
            accountEmails.get(contact.AccountId).add(contact.Email);
        }

        // Prepare Emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (AgriEdge_Order__c order : orders) {

            if (accountEmails.containsKey(order.Customer__c)) {

                List<String> toEmails = accountEmails.get(order.Customer__c);

                String emailBody = 'Dear Customer,<br/><br/>'
                    + 'Your order has been updated with the following details:<br/><br/>'
                    + '<b>Order Name:</b> ' + order.Name + '<br/>'
                    + '<b>Order Status:</b> ' + order.Order_Status__c + '<br/>'
                    + '<b>Total Amount:</b> ' + order.Total_Amount__c + '<br/>'
                    + '<b>Payment Status:</b> ' + order.Payment_Status__c + '<br/>'
                    + '<b>Created Date:</b> ' + order.CreatedDate + '<br/><br/>'
                    + 'Thank you for your business!<br/><br/>'
                    + 'Best Regards,<br/>Your Company Name';

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toEmails);
                email.setSubject('Your Order Payment Status has been Updated');
                email.setHtmlBody(emailBody);

                emails.add(email);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
