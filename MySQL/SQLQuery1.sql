if exists(select* from sys.databases where name='Test3')  --�ж��Ƿ���ڸ����ݿ⣬���ھͽ���ɾ��
   drop database Test3
create database Test3  --�������ݿ������
on(                    --�����ļ�       
   name='Test3',       --���ݿ���߼�����
   filename='C:\Users\mzc\Desktop\���ݿ�ԭ��Ӧ��\SaveData\Test3.mdf',  --����·��
   size=5MB,           --��ʼ���ݿ�Ĵ�С
   filegrowth=1MB      --���ݿ������Ĵ�С
)
log on                 --��־�ļ�
(
   name='Test3_log',   --��־�ļ����߼�����
   filename='C:\Users\mzc\Desktop\���ݿ�ԭ��Ӧ��\SaveData\Test3_log.ldf',--����·��
   size=5MB,           --��ʼ��С
   filegrowth=1MB      --������С
)

--���ݿⴴ���ļ�д(ȫ����ȡĬ��ֵ)
create database Test4