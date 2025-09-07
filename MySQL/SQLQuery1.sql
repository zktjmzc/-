if exists(select* from sys.databases where name='Test3')  --判断是否存在该数据库，存在就进行删除
   drop database Test3
create database Test3  --创建数据库的名称
on(                    --数据文件       
   name='Test3',       --数据库的逻辑名称
   filename='C:\Users\mzc\Desktop\数据库原理及应用\SaveData\Test3.mdf',  --物理路径
   size=5MB,           --初始数据库的大小
   filegrowth=1MB      --数据库增长的大小
)
log on                 --日志文件
(
   name='Test3_log',   --日志文件的逻辑名称
   filename='C:\Users\mzc\Desktop\数据库原理及应用\SaveData\Test3_log.ldf',--物理路径
   size=5MB,           --初始大小
   filegrowth=1MB      --增长大小
)

--数据库创建的简写(全部采取默认值)
create database Test4