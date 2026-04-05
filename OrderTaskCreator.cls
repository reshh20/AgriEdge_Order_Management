public with sharing class OrderTaskCreator {

    @InvocableMethod

    public static void createTaskForNewOrder(List<Id> orderIds) {

        if (orderIds == null || orderIds.isEmpty()) {

            return;

        }




        

        List<User> platformUsers = [SELECT Id FROM User WHERE Profile.Name = 'Platform 1' LIMIT 10];




        

        if (platformUsers.isEmpty()) {

            System.debug('No users found with Platform 1 profile.');

            return;

        }




        List<Task> tasks = new List<Task>();




        for (Id orderId : orderIds) {

            for (User user : platformUsers) {

                Task newTask = new Task(

                    Subject = 'New Order Created',

                    Description = 'Order Id:'+orderId,
                

                    OwnerId = user.Id,

                    Status = 'Not Started',

                    Priority = 'High'

                );

                tasks.add(newTask);

            }

        }




        if (!tasks.isEmpty()) {

            insert tasks;

        }

    }

}
