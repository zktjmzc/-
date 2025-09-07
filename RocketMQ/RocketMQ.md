---
date: 2025-08-18
aliases:
  - RocketMQ
tags:
  - MQ
  - RocketMQ
  - RocketMQ控制台
  - 一对一关系
  - 多消费者
  - 消息类型
  - 消息过滤
---
# MQ
---
#### 1、简介
	消息队列的简称，多个工程之间相互的传递消，在消息传递过程中保存消息的容器，多用于分布式系统用之间的通信
### 2、qps
指系统每秒中能够处理的请求数量，常与TPS（事务数每秒）、RT（响应时间）、并发数用来评估性能
### 3、生产者和消费者
	生产者：请求方
	消费者：响应方
### 4、优劣
	优势：应用解耦
		异步提速
		削峰填谷
	劣势：系统可用性降低
		系统复杂度提高
		一致性问题
### 5、应用解耦
	消费者出现了问题，或者传输途中出现了问题，不会影响生产者发送消息，例如，向多个消费者发送消息，而不是强邦到某个听定的消费者
### 6、异步提速
	即传输处理消息的流程中，每个消费者之间是独立处理的，并行执行，而不是串行，提高响应速度
### 7、削峰填谷
	当出现当量的并发请求，MQ对于消息进行限速，充当缓存的作用，这样高峰期，消费者方不会收到过量的信息，出现崩溃，这就是削峰，而当峰值过去后，发送给消费者的并发量不会减少，而是继续处理堆积在MQ中的信息，这就是添谷，提高了系统的稳定性

### 8、种类
	RabbitMQ：erlang语言实现，万级吞吐，处理us级，主从架构
	RocketMQ：十万级吞吐，速度ms，分布式架构，功能强大，扩展性强
	kafka：和RocketMQ差不多，功能少，多应用于大数据，scala语言实现
### 9、流程
![[Pasted image 20250818110205.png]]


# RocketMQ安装
---
### 1、官网下载
[https://rocketmq.apache.org/download]
### 2、解压
### 3、配置环境变量
	在系统环境变量中创建ROCKETMQ_HOME,
	路径为：E:\RocketMQ\rocketmq-all-5.3.3-bin-release\bin（以解压位置为准）
### 4、启动
	在rocketmq-all-5.3.3-bin-release\bin文件目录下进入cmd
	启动NameServer
```cmd
start mqnamesrv.cmd
```
	启动Broker（这里的绝对路径可以改为相对路径）
```cmd
start mqbroker.cmd -c E:\RocketMQ\rocketmq-all-5.3.3-bin-release\conf\broker.conf
```
### 5、测试
	测试RocketMQ是否可用
#### （1）配置环境变量
	添加NAMESRV_ADDR,变量值：localhost:9876
#### （2）测试生产者，即broker是否能够接收
	重进一下bin中的cmd窗口，并输入
```cmd
tools.cmd org.apache.rocketmq.example.quickstart.Producer
```
#### （3）测试消费者
	输入以下内容
```cmd
tools.cmd org.apache.rocketmq.example.quickstart.Consumer
```

## RocketMQ控制台安装
---
#### 1、将项目克隆到本地中
	地址：https://github.com/apache/rocketmq-dashboard
### 2、执行命令（编译打包）
```cmd
//编译
$ mvn clean package -Dmaven.test.skip=true
//运行
$ java -jar target/rocketmq-dashboard-1.0.1-SNAPSHOT.jar
```


## 一对一关系
---
### 1、生产者
```java
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        DefaultMQProducer producer = new DefaultMQProducer("group1");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        producer.start();  
  
        //4、发什么  
        String s="hello world";  
        Message message = new Message("topic1","tag1",s.getBytes(StandardCharsets.UTF_8));  
        SendResult send = producer.send(message);  
        //5、发送的结果是什么  
        System.out.println(send);  
        //6、关闭连接  
        producer.shutdown();  
    }  
}
```
### 2、消费者
```java
public class Consumer {  
    public static void main(String[] args) throws Exception{  
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("group1");  
        //从哪里收  
        consumer.setNamesrvAddr("localhost:9876");  
        //监听哪个消息队列  
        consumer.subscribe("topic1","*");  
        //处理业务流程  
        //注册一个消息的监听器  
        //ConsumeConcurrentlyContext:获取当前队列的上下文信息，如，context.getMessageQueue()获取处于哪个队列  
        consumer.registerMessageListener(new MessageListenerConcurrently() {  
            @Override  
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> list, ConsumeConcurrentlyContext consumeConcurrentlyContext) {  
                //写出业务逻辑  
                if (!list.isEmpty()) {  
                    for (MessageExt messageExt : list) {  
                        byte[] body = messageExt.getBody();  
                        System.out.println(new String(body));  
                    }  
                    return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;  
                }else return ConsumeConcurrentlyStatus.RECONSUME_LATER;  
            }  
        });  
        consumer.start();  
  
  
        //不要关闭消费者  
  
    }  
}
```


## 多消费者模式
---
### 1、负载均衡
	当有多个消费者监听一个生产者的时候，会将消息平均的传递给监听对应主题的消费者，提高效率
注：消费者在同一组，且没有声明是广播模式（默认为负载均衡）
### 2、广播模式
	不同组的消费者接收到生产者的消息数量是一致的，同一组的也可以将模式调为广播模式
### 3、代码展示
	生产者（模拟多次发送）
```java
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        DefaultMQProducer producer = new DefaultMQProducer("group1");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        producer.start();  
        //4、发什么  
        for (int i=0;i<10;i++) {  
            String s="Hello Rocket"+i;  
            Message message = new Message("topic2","tag1",s.getBytes(StandardCharsets.UTF_8));  
            SendResult send = producer.send(message);  
            //5、发送的结果是什么  
            System.out.println(send);  
        }  
        //6、关闭连接  
        producer.shutdown();  
    }  
}
```
	消费者（同时启动多个去捕捉一个主题）
```java
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        DefaultMQProducer producer = new DefaultMQProducer("group1");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        producer.start();  
        //4、发什么  
        for (int i=0;i<10;i++) {  
            String s="Hello Rocket"+i;  
            Message message = new Message("topic2","tag1",s.getBytes(StandardCharsets.UTF_8));  
            SendResult send = producer.send(message);  
            //5、发送的结果是什么  
            System.out.println(send);  
        }  
        //6、关闭连接  
        producer.shutdown();  
    }  
}
```
## 消息类型
---
### 1、同步消息
	简介：及时性强，例如，短信，通知（转账）
	代码演示：之前的代码就是即时消息
### 2、异步消息
	简介：及时性弱，只要有消息即可，例如订单中的信息
	注意：由于是异步的，一次代码在执行完发送消息后，不会立刻接收，而是继续执行下面的代码，
		所以在异步消息中，不能够直接关闭生产者
```java
//异步消息-----生产者  
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        DefaultMQProducer producer = new DefaultMQProducer("group1");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        producer.start();  
        //4、发什么  
        String s="Hello Rocket";  
        Message message = new Message("topic1","tag1",s.getBytes(StandardCharsets.UTF_8));  
        producer.send(message, new SendCallback() {  
            //成功时返回的消息  
            @Override  
            public void onSuccess(SendResult sendResult) {  
                System.out.println(sendResult);  
            }  
  
            //失败是返回的消息  
            @Override  
            public void onException(Throwable throwable) {  
                System.out.println(throwable);  
            }  
        });  
  
        System.out.println("执行成功");  
    }  
}
```
### 3、延时消息
（1）作用：消息发送时并不直接发送到消息服务器，而根据等待时间到达，起到演示缓冲的作用
（2） 支持的延迟时间
![[Pasted image 20250818163027.png]]
（3）代码展示
```java
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        DefaultMQProducer producer = new DefaultMQProducer("group1");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        producer.start();  
        //4、发什么  
        String s="Hello Rocket";  
        Message message = new Message("topic1","tag1",s.getBytes(StandardCharsets.UTF_8));  
        //设置延时时间  
        message.setDelayTimeLevel(3);  //延时3秒  
        producer.send(message);  
  
        System.out.println("执行成功");  
    }  
}
```
### 4、批量消息
	简介：一次性发送多条消息
	注意
		批量发送的消息尽可能是同一个topic
		发送的消息类型也是一样的
		不能发延时消息
		总长度不超过4M
		长度包含：topic、body、消息追加的属性、日志
	代码展示

![[Pasted image 20250818163629.png]]
## 消息过滤
---
	简介：消费者对于接收到的消息进行过滤处理
#### （1）Tag过滤
代码展示
![[Pasted image 20250818164435.png]]
或者
![[Pasted image 20250818165202.png]]
#### （2）sql过滤
	首先，开启sql过滤，打开RocketMQ\rocketmq-all-5.3.3-bin-release\conf文件夹中的
	broker.conf
	然后，在上面添加enablePropertyFilter = true，关闭并保存，之后重启RocketMQ即可开启
代码展示
	生产者
```java
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        DefaultMQProducer producer = new DefaultMQProducer("group1");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        producer.start();  
        //4、发什么  
        String s="Hello Rocket";  
        Message message = new Message("topic5","tag1",s.getBytes(StandardCharsets.UTF_8));  
        //消息追加属性(可以追加多个)  
        message.putUserProperty("name","张三");  
        message.putUserProperty("age","18");  
        producer.send(message);  
  
        System.out.println("执行成功");  
    }  
}
```
	消费者
```java
public class Consumer {  
    public static void main(String[] args) throws Exception{  
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("group1");  
        //从哪里收  
        consumer.setNamesrvAddr("localhost:9876");  
        //基于sql进行过滤  
        consumer.subscribe("topic5", MessageSelector.bySql("age > 16"));  
  
        consumer.registerMessageListener(new MessageListenerConcurrently() {  
            @Override  
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> list, ConsumeConcurrentlyContext consumeConcurrentlyContext) {  
                    //写出业务逻辑  
                    for (MessageExt messageExt : list) {  
                        System.out.println(messageExt);  
                        byte[] body = messageExt.getBody();  
                        System.out.println(new String(body));  
                    }  
                    return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;  
            }  
        });  
        consumer.start();  
  
  
        //不要关闭消费者  
  
    }  
}
```

## SpringBoot整合RocketMQ
---
### 1、导入maven坐标
```xml
<dependency>  
    <groupId>org.apache.rocketmq</groupId>  
    <artifactId>rocketmq-spring-boot-starter</artifactId>  
    <version>2.3.1</version> <!-- 版本号根据你的 RocketMQ 版本选择 -->  
</dependency>
```
### 2、编写配置类
```yml
rocketmq:  
  name-server: localhost:9876  
  producer:  
    group: group1
```
### 3、业务流程
	（1）在Controller层接收到请求
```java
@RestController  
@RequestMapping("/demo")  
public class Producer {  
    @Autowired  
    private UserService userService;  
  
    @GetMapping("/send")  
    public String send(){  
        User user=new User("张三",18);  
        //在topic后面加上:标签名，用来添加tag  
        userService.createUserProducer(user);  
  
        return "Success";  
    }  
}
```
	（2）在Service层调用生产者
```java
@Service  
public class UserService {  
  
    @Autowired  
    private RocketMQTemplate rocketMQTemplate;  
  
    public void createUserProducer(User user){  
        rocketMQTemplate.convertAndSend("Topic:userCreate",user);  
    }
}    
```
	（3）在消费者上接收业务
```java
@Component  
@RocketMQMessageListener(  
        topic = "Topic",  
        selectorExpression ="userCreate",   //tag过滤，默认为*  
        consumerGroup = "my-consumer-group"  
)  
public class OrderCreateListener implements RocketMQListener<User> {  
    @Autowired  
    private UserService userService;  
  
    @Override  
    public void onMessage(User user) {  
        //将处理逻辑写在Service中  
        userService.createUser(user);  
    }  
}
```
	（4）Service层中书写对应的处理逻辑
```java
@Service  
public class UserService {  
    public void createUser(User user){  
        System.out.println(user.toString());  
    }  
}
```
### 4、各种消息类型、过滤方式、消费者模式
	各种消息模式、sql过滤
	消费者
```java
public void createUserProducer(User user){  
    //一般消息  
    rocketMQTemplate.convertAndSend("Topic:userCreate",user);  
    //同步消息  
    rocketMQTemplate.syncSend("Topic:userCreate",user);  
    //异步消息  
    //匿名内部类方法-----异步消息只使用一次  
    rocketMQTemplate.asyncSend("Topic:userCreate", user, new SendCallback() {  
        @Override  
        public void onSuccess(SendResult sendResult) {  
            System.out.println(sendResult);  
        }  
  
        @Override  
        public void onException(Throwable throwable) {  
            System.out.println(throwable);  
        }  
    },100);  
  
    //单向消息  
    rocketMQTemplate.sendOneWay("Topic:userCreate",user);  
    //延时消息  
    rocketMQTemplate.syncSend("Topic:userCreate", MessageBuilder.withPayload(user).build(),100,3);  
    //批量消息  
    List<Message>list=new ArrayList<>();  
    rocketMQTemplate.syncSend("Topic:userCreate",list,100);  
    //sql过滤  
    rocketMQTemplate.syncSend(  
            "Topic:userCreate",  
            MessageBuilder.withPayload(user)  
                    .setHeader("age",String.valueOf(user.getAge()))  
                    .build(),  
            100  
    );  
}
```
	生产者
```java
@Component  
@RocketMQMessageListener(  
        topic = "Topic",  
        selectorType = SelectorType.SQL92,//不设置默认为tag过滤  
        selectorExpression ="age>16",   //sql过滤  
        consumerGroup = "my-consumer-group",  
        messageModel = MessageModel.BROADCASTING  //可以调节消费者模式，当前为广播模式  
)  
public class OrderCreateListener implements RocketMQListener<User> {  
    @Autowired  
    private UserService userService;  
  
    @Override  
    public void onMessage(User user) {  
        //将处理逻辑写在Service中  
        userService.createUser(user);  
    }  
}
```

## 消息的特殊处理
---
### （1）消息顺序
	简介：不加控制的消息发送会出现消息混乱的情况
	实现效果：队列内有序，队列外无序
	解决方法
		让相关联的消息放在一个队列中，这样关联消息会按照入队时的顺序进行返回
代码展示
	生产者
```java
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        DefaultMQProducer producer = new DefaultMQProducer("group1");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        producer.start();  
        //4、发什么  
        List<User>list=new ArrayList<>();  
        User userTemp=new User();  
        list.add(userTemp);  
//      .......  省略添加  
        for (User user : list) {  
            Message message = new Message("Topic", "tag", user.toString().getBytes());  
            producer.send(message, new MessageQueueSelector() {  
//              实现队列的选择方法  
                @Override  
                public MessageQueue select(List<MessageQueue> list, Message message, Object o) {  
                    //获得其队列的id  
                    //这里选择队列的方法是利用用户id去获取的，用户id相同的会被有序分配到一个队列中  
                    int id = user.getId() % list.size();  
                    //取出确定的队列  
                    return list.get(id);  
                }  
            },null);  
        }  
    }  
}
```
	消费者
```java
public class Consumer {  
    public static void main(String[] args) throws Exception {  
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("group1");  
        //从哪里收  
        consumer.setNamesrvAddr("localhost:9876");  
        //监听哪个消息队列  
        consumer.subscribe("topic1", "*");  
        //消费者的代码做对应的修改  
        //按顺序取队列，每个队列都去对头，所有都去一遍后，再从头继续去取  
        consumer.registerMessageListener(new MessageListenerOrderly() {  
            @Override  
            public ConsumeOrderlyStatus consumeMessage(List<MessageExt> list, ConsumeOrderlyContext consumeOrderlyContext) {  
                //写出业务逻辑  
                for (MessageExt messageExt : list) {  
                    byte[] body = messageExt.getBody();  
                    System.out.println(new String(body));  
                }  
                return ConsumeOrderlyStatus.SUCCESS;  
            }  
        });  
        consumer.start();  
    }  
}
```
## 事务消息流程
---
	作用：当所要发送的消息非常的重要，要保证消息不能够丢失，因此采用事务的方式发送
#### 发送流程（类似于TCP的建立连接）
![[Pasted image 20250819120502.png]]
#### 事务补偿
![[Pasted image 20250819120747.png]]
### 代码实现
##### （1）正常事务流程
	生产者
```java
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        TransactionMQProducer producer = new TransactionMQProducer("group10");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        //设置事务的监听  
        producer.setTransactionListener(new TransactionListener() {  
            //正常事务的过程  
            @Override  
            public LocalTransactionState executeLocalTransaction(Message message, Object o) {  
                //把事务保存到mysql数据库中  
//                insert ....  
//                根据是否提交成功返回不同的结果  
//                if (){  
//  
//                }else {  
//  
//                }  
                //这里假设传输成功了，返回提交  
                System.out.println("执行了正常的事务过程");  
                return LocalTransactionState.COMMIT_MESSAGE;  
            }  
  
            //事务补偿的过程  
            @Override  
            public LocalTransactionState checkLocalTransaction(MessageExt messageExt) {  
                return null;  
            }  
        });  
        producer.start();  
        //发送消息  
        String s="Hello Rocket";  
        Message message = new Message("topic10","tag1",s.getBytes(StandardCharsets.UTF_8));  
        //发送事务消息  
        TransactionSendResult result = producer.sendMessageInTransaction(message, null);  
        System.out.println(result);  
  
        //不能够关闭生产者  
    }  
}
```
	消费者：正常书写
##### （2）事务回滚
	生产者
```java
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        TransactionMQProducer producer = new TransactionMQProducer("group10");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        //设置事务的监听  
        producer.setTransactionListener(new TransactionListener() {  
            //正常事务的过程  
            @Override  
            public LocalTransactionState executeLocalTransaction(Message message, Object o) {  
                //把事务保存到mysql数据库中  
//                insert ....  
//                根据是否提交成功返回不同的结果  
//                if (){  
//  
//                }else {  
//  
//                }  
                //这里假设传输成功了，返回提交  
                System.out.println("执行了事务回滚");  
                return LocalTransactionState.ROLLBACK_MESSAGE;  
            }  
  
            //事务补偿的过程  
            @Override  
            public LocalTransactionState checkLocalTransaction(MessageExt messageExt) {  
                return null;  
            }  
        });  
        producer.start();  
        //发送消息  
        String s="Hello Rocket";  
        Message message = new Message("topic10","tag1",s.getBytes(StandardCharsets.UTF_8));  
        //发送事务消息  
        TransactionSendResult result = producer.sendMessageInTransaction(message, null);  
        System.out.println(result);  
  
        //不能够关闭生产者  
    }  
}
```
	消费者：与原来保持一致
#### （3）事务补偿
	生产者
```java
public class Producer {  
    public static void main(String[] args) throws Exception {  
        //1、谁来发？  
        TransactionMQProducer producer = new TransactionMQProducer("group10");  
        //2、发给谁？  
        producer.setNamesrvAddr("localhost:9876");  
        //设置事务的监听  
        producer.setTransactionListener(new TransactionListener() {  
            //正常事务的过程  
            @Override  
            public LocalTransactionState executeLocalTransaction(Message message, Object o) {  
                System.out.println("执行正常事务流程");  
                //把事务保存到mysql数据库中  
//                insert ....  
//                根据是否提交成功返回不同的结果  
//                if (){  
//  
//                }else {  
//  
//                }  
                //这里假设传输成功了，返回提交  
                return LocalTransactionState.UNKNOW;  
            }  
  
            //事务补偿的过程  
            @Override  
            public LocalTransactionState checkLocalTransaction(MessageExt messageExt) {  
                System.out.println("执行事务补偿");  
                // insert...  
//                if () {  
//  
//                } else {  
//                }  
                //事务提交或者回滚都可以  
                //如果还是unknown，则需要运维介入
                return LocalTransactionState.COMMIT_MESSAGE;  
            }  
        });  
        producer.start();  
        //发送消息  
        String s="Hello Rocket";  
        Message message = new Message("topic10","tag1",s.getBytes(StandardCharsets.UTF_8));  
        //发送事务消息  
        TransactionSendResult result = producer.sendMessageInTransaction(message, null);  
        System.out.println(result);  
  
        //不能够关闭生产者  
    }  
}
```
	消费者：和之前一样
## 集群搭建
---
### 1、主从同步
	同步方式
		同步：当主节点接收到消息后，锁住，传输消息给从节点，然后再返回消息给发送者
		异步：当主节点接收到消息后，过一会儿发给从节点，立刻给发送者返回消息
#### 实现流程 
![[Pasted image 20250819130553.png]]
### 2、两主两从
![[Pasted image 20250819130958.png]]

### 3、搭建流程
#### （1）下载
	下载RocketMQ的压缩包，导入到linux中，移到/目录下，然后，更改为rocketmq
### （2）配置
	首先，配置好jdk环境
	然后，在rocketmq文件下创建store、store-slave两个文件夹
	之后，分别在里面创建三个文件夹，commitlog、consumequeue、index
	再然后，进入conf文件夹，找到2m-2s-sync文件夹
	一号虚拟机保留，broker-a.properties和broker-b-s.properties
	二号虚拟机保留，broker-a-s.properties和broker-b.properties
	用vim分别打开，进行配置，配置如下
二号机：broker-a-s.properties
```shell
brokerClusterName=rocketmq-cluster
brokerName=broker-a
brokerId=1
namesrvAddr=rocketmq-nameserver1:9876;rocketmq-nameserver2:9876
defaultTopicQueueNums=4
autoCreateTopicEnable=true
autoCreateSubscriptionGroup=true
listenPort=11011
deletewhen=04
fileReservedTime=120
mapedFileSizeCommitLog=1073741824
mapedFileSizeConsumeQueue=300000
diskMaxUsedSpaceRatio=88
storePathRootDir=/rocketmq/store-slave
storePathCommitLog=/rocketmq/store-slave/commitlog
storePathConsumeQueue=/rocketmq/store-slave/consumequeue
storePathIndex=/rocketmq/store-slave/index
storeCheckpoint=/rocketmq/store-slave/checkpoint
abortFile=/rocketmq/store-slave/abort
maxMessageSize= 65536
brokerRole=SLAVE
flushDiskType=ASYNC_FLUSH
```
二号机：broker-b.properties
```shell
brokerClusterName=rocketmq-cluster
brokerName=broker-b
brokerId=0
namesrvAddr=rocketmq-nameserver1:9876;rocketmq-nameserver2:9876
defaultTopicQueueNums=4
autoCreateTopicEnable=true
autoCreateSubscriptionGroup=true
listenPort=10911
deletewhen=04
fileReservedTime=120
mapedFileSizeCommitLog=1073741824
mapedFileSizeConsumeQueue=300000
diskMaxUsedSpaceRatio=88
storePathRootDir=/rocketmq/store
storePathCommitLog=/rocketmq/store/commitlog
storePathConsumeQueue=/rocketmq/store/consumequeue
storePathIndex=/rocketmq/store/index
storeCheckpoint=/rocketmq/store/checkpoint
abortFile=/rocketmq/store/abort
maxMessageSize= 65536
brokerRole=SYNC_MASTER
flushDiskType=SYNC_fLUSH
```
一号机：broker-a.properties
```shell
brokerClusterName=rocketmq-cluster
brokerName=broker-a
brokerId=0
namesrvAddr=rocketmq-nameserver1:9876;rocketmq-nameserver2:9876
defaultTopicQueueNums=4
autoCreateTopicEnable=true
autoCreateSubscriptionGroup=true
listenPort=10911
deletewhen=04
fileReservedTime=120
mapedFileSizeCommitLog=1073741824
mapedFileSizeConsumeQueue=300000
diskMaxUsedSpaceRatio=88
storePathRootDir=/rocketmq/store
storePathCommitLog=/rocketmq/store/commitlog
storePathConsumeQueue=/rocketmq/store/consumequeue
storePathIndex=/rocketmq/store/index
storeCheckpoint=/rocketmq/store/checkpoint
abortFile=/rocketmq/store/abort
maxMessageSize= 65536
brokerRole=SYNC_MASTER
flushDiskType=SYNC_fLUSH
```
一号机：broker-b-s.properties
```shell
brokerClusterName=rocketmq-cluster
brokerName=broker-b
brokerId=1
namesrvAddr=rocketmq-nameserver1:9876;rocketmq-nameserver2:9876
defaultTopicQueueNums=4
autoCreateTopicEnable=true
autoCreateSubscriptionGroup=true
listenPort=11011
deletewhen=04
fileReservedTime=120
mapedFileSizeCommitLog=1073741824
mapedFileSizeConsumeQueue=300000
diskMaxUsedSpaceRatio=88
storePathRootDir=/rocketmq/store-slave
storePathCommitLog=/rocketmq/store-slave/commitlog
storePathConsumeQueue=/rocketmq/store-slave/consumequeue
storePathIndex=/rocketmq/store-slave/index
storeCheckpoint=/rocketmq/store-slave/checkpoint
abortFile=/rocketmq/store-slave/abort
maxMessageSize= 65536
brokerRole=SLAVE
flushDiskType=ASYNC_FLUSH
```
### （3）设置大小
	进入bin文件名，vim打开runserver.sh，找到类似
```shell
JAVA_OPT="${JAVA_OPT} -server -Xms4g -Xmx4g -Xmn2g"
```
	修改大小为256m,256m,256m
### （4）启动
	在bin目录下，输入指令
```shell
#启动nameserver
nohup sh mqnamesrv &
#启动broker进程
 nohup sh mqbroker -c ../conf/2m-2s-sync/根据对应的配置文件 &
```
### （5）测试
```shell
#添加测试环境（一号虚拟机）
export NAMESRV_ADDR=rocketmq-nameserver1:9876
#生产者测试
sh tools.sh org.apache.rocketmq.example.quickstart.Producer
#消费者测试
sh tools.sh org.apache.rocketmq.example.quickstart.Consumer
```
## 高级特性
---
#### （1）消息存储特性
![[Pasted image 20250820105515.png]]
#### （2）高效读写
	预先申请：broker提前向文件系统申请一片区域，之后写入时可以顺序写入，大大提高速度
	利用linux中的零拷贝技术

![[Pasted image 20250820110624.png]]
### （3）高效存储的物理地址
	构成
		commitlog：核心存储文件，所有消息都写入其中
		consumequeue：类似于消息索引文件，帮助消费者快速定位消息在commitlog中的物理位置
					按照topic+queueid划分，只存储指针和索引信息
		index：用来根据消息的 Key 或者时间区间快速检索消息

![[Pasted image 20250820111518.png]]
### （4）刷盘机制
	同步刷盘：
		生产者发送消息到MQ，MQ接收到消息
		MQ将挂起生产者发送消息的线程
		MQ将消息存储到内存中
		内存将数据写入磁盘
		磁盘传回SUCCESS
		MQ回复挂起的线程
		发送ACK给生产者
	异步刷盘：
		生产者发送消息给MQ
		MQ将消息存储到内存中
		MQ返回ACK给生产者
		等消息到达一定量后，内存将消息写入磁盘中
### （5）高可用
	nameserver
		无状态（相互独立）+全服务器注册（broker每台nameserver都进行注册）
	消息服务器
		主从架构
	消息生产
		生产者将相同的topic绑定到多个组，保证一个挂掉后，其它仍然可以接受消息
	消息消费
		RocketMQ根据master的压力，决定是否将消息读取分给slave承担
### （6）负载均衡
	Producer负载均衡
		内部实现了不用broker集群中对同一topic对应消息队列的负载均衡
	Consumer负载均衡
		平均分配
		循环平均分配（防止其中broker中某一个messageQueue挂掉，使其中一个消费者处于空闲状态）
### （7）消息重试
	当消息消费后未正常返回消费成功的信息将启动消息重试机制
	消息重试机制
		顺序消息
			当消费者消费消息失败后，RocketMQ会自动进行消息重试
			注意：应用会出现消息消费被阻塞的情况，因此，要对消息的消费情况监控，避免阻塞发生
		无序消息
			除普通消息、定时、延时、事务消息外的称为无序消息
			无序消息仅适用于负载均衡模式下的消息消费，不适用于广播模式的消息消费
				原因：广播模式下，broker不会追踪每个消费者的消费结果
			MQ指定了合理的无序消息重试间隔，会越来越长，最多16次
### （8）死信队列
	简介：重试16次后，MQ无法正常消费的消息称为死信消息，其不会被直接抛弃，而是存放在死信队列中
	死信队列的特征：
		归属于一个组，不属于任何一个topic；
		可以包含多个topic的死信消息
	死信队列中消息的特征：
		不会被再次消费
		有效期为3天，到时会被清除
	处理：
		在监控平台中，查找死信，确定死信的messageId，然后根据id对死信进行精准消费
### （9）重复消费
	原因：
		生产者重复发送：网络闪断，生产者没有收到ack，一次重发
					生产者宕机
		消息服务器重复发送：网络闪断，broker没有收到消费者的ack，重复发送
		动态的负载均衡过程
					网络闪断
					broker重启
					订阅方应用重启
					客户端扩容、缩容
### （10）消息幂等性
	对于同一条消息，无论消费多少次，结果保持一致，称为消息幂等性
	即当多次发送这个消息，理论上返回的结果是一致的，例如，查询操作
	解决方法：
		将业务id作为消息的key（唯一性）
		消费消息时，客户端对key做判定，未使用过的放行，使用过的抛弃
	注：messageId有RocketMQ产生，其不具有唯一性，不能作为幂等性判定条件
常见幂等场景
![[Pasted image 20250820123330.png]]