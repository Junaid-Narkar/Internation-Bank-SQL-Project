CREATE DATABASE CASESTUDY3

USE CASESTUDY3;

--Problem Statement:
--You are the database developer of an international bank. You are responsible for
--managing the bank’s database. You want to use the data to answer a few
--questions about your customers regarding withdrawal, deposit and so on,
--especially about the transaction amount on a particular date across various
--regions of the world. Perform SQL queries to get the key insights of a customer.


--Dataset:

--The 3 key datasets for this case study are:

--a. Continent: The Continent table has two attributes i.e., region_id and
--region_name, where region_name consists of different continents such as
--Asia, Europe, Africa etc., assigned with the unique region id.

--b. Customers: The Customers table has four attributes named customer_id,
--region_id, start_date and end_date which consists of 3500 records.

--c. Transaction: Finally, the Transaction table contains around 5850 records
--and has four attributes named customer_id, txn_date, txn_type and
--txn_amount.

SELECT * FROM CONTINENT;
SELECT * FROM CUSTOMERS;
SELECT * FROM [dbo].[Transaction];

--1. Display the count of customers in each region who have done the
--transaction in the year 2020.

Select Count(*) As No_Of_Coustomer,Year(Txn_date) from [dbo].[Transaction]
Group by Year(Txn_date)
Having Year(Txn_Date) = '2020';

Select co.region_name,count(Distinct t.customer_id) As Coustomer_Count from [dbo].[Transaction] As t
join customers as c 
on t.customer_id = c.customer_id
join continent as co
on c.region_id = co.region_id
Where Year(t.txn_date)='2020'
Group by co.region_name

--2. Display the maximum and minimum transaction amount of each
--transaction type.

Select txn_Type,count(txn_type) as No_of_transaction,Max(txn_amount) as Max_amount,min(txn_amount) as min_amount from [dbo].[Transaction]
Group by txn_type;

SELECT * FROM [dbo].[Transaction];


--3. Display the customer id, region name and transaction amount where
--transaction type is deposit and transaction amount > 2000.

Select c.customer_id,co.region_name,t.txn_amount from customers as c
inner join Continent as co
on c.region_id = co.region_id
inner join [dbo].[Transaction] as t
on c.customer_id = t.customer_id
where txn_type = 'deposit' and txn_amount > 2000;


--4. Find duplicate records in the Customer table.

Select customer_id,region_id,start_date,end_date,count(*) As duplicate_count from customers
Group by customer_id,region_id,start_date,end_date
Having count(*)>1;



--5. Display the customer id, region name, transaction type and transaction
--amount for the minimum transaction amount in deposit.

Select t.customer_id,co.region_name,t.txn_type,t.txn_amount from[dbo].[Transaction] as t
inner join customers as c
on t.customer_id = c.customer_id
inner join Continent as co
on c.region_id = co.region_id
where t.txn_type = 'Deposit' and
t.txn_amount = (select min(txn_amount) from [dbo].[Transaction] where txn_type = 'Deposit')


--6. Create a stored procedure to display details of customers in the
--Transaction table where the transaction date is greater than Jun 2020.

CREATE PROCEDURE GetTransactionAfterJun2020
AS
BEGIN
    SELECT t.* 
    FROM [dbo].[Transaction] AS t
    WHERE t.txn_date > '2020-06-30';
END;

Exec GetTransactionAfterJun2020;


--7. Create a stored procedure to insert a record in the Continent table.

Create Procedure InsertContinentRecord (@p_region_Id int,@p_region_name varchar(250))
As
Begin
     Insert Into Continent (region_id,region_name)
	 Values(@p_region_id,@p_region_name);
End


--8. Create a stored procedure to display the details of transactions that
--happened on a specific day.

Create Procedure GetTransactionByDate (@p_date Date)
As
Begin
     Select t.* from [dbo].[Transaction] as t
	 where t.txn_date = @p_date;
End;


--9. Create a user defined function to add 10% of the transaction amount in a
--table.

Create function AddTenPercent (@p_amount Decimal (18,2))
Returns Decimal(18, 2)
As
Begin
     Return @p_amount*1.10;
end;


--10. Create a user defined function to find the total transaction amount for a
--given transaction type.

CREATE FUNCTION TotalTransactionAmount (@p_txn_type VARCHAR(255))
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @total_amount DECIMAL(18, 2);

    SELECT @total_amount = SUM(txn_amount)
    FROM [dbo].[Transaction]
    WHERE txn_type = @p_txn_type;

    RETURN @total_amount;
END;


--11. Create a table value function which comprises the columns customer_id,
--region_id ,txn_date , txn_type , txn_amount which will retrieve data from
--the above table.

CREATE FUNCTION GetTransactionDetails()
RETURNS TABLE
AS
RETURN
    SELECT 
        t.customer_id AS TransactionCustomerID,
        c.region_id,
        t.txn_date,
        t.txn_type,
        t.txn_amount
    FROM [dbo].[Transaction] AS t
    JOIN Customers AS c ON t.customer_id = c.customer_id;


--12. Create a TRY...CATCH block to print a region id and region name in a
--single column.

BEGIN TRY
    SELECT CONCAT(region_id, ' - ', region_name) AS region_info
    FROM Continent;
END TRY
BEGIN CATCH
    PRINT 'An error occurred while retrieving region information.';
END CATCH;


--13. Create a TRY...CATCH block to insert a value in the Continent table.

BEGIN TRY
    INSERT INTO Continent (region_id, region_name) VALUES (101, 'Antarctica');
    PRINT 'Record inserted successfully.';
END TRY
BEGIN CATCH
    PRINT 'An error occurred while inserting into the Continent table.';
END CATCH;


--14. Create a trigger to prevent deleting a table in a database.

CREATE TRIGGER PreventTableDeletion
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    PRINT 'Deleting tables is not allowed in this database.';
    ROLLBACK;
END;

--15. Create a trigger to audit the data in a table.

CREATE TRIGGER AuditTransaction
ON [dbo].[Transaction]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Handle INSERT operations
    INSERT INTO Transaction_Audit (customer_id, txn_date, txn_type, txn_amount, action, action_date)
    SELECT 
        customer_id, 
        txn_date, 
        txn_type, 
        txn_amount, 
        'INSERT' AS action, 
        GETDATE() AS action_date
    FROM INSERTED;

    -- Handle DELETE operations
    INSERT INTO Transaction_Audit (customer_id, txn_date, txn_type, txn_amount, action, action_date)
    SELECT 
        customer_id, 
        txn_date, 
        txn_type, 
        txn_amount, 
        'DELETE' AS action, 
        GETDATE() AS action_date
    FROM DELETED;

    -- Handle UPDATE operations
    INSERT INTO Transaction_Audit (customer_id, txn_date, txn_type, txn_amount, action, action_date)
    SELECT 
        customer_id, 
        txn_date, 
        txn_type, 
        txn_amount, 
        'UPDATE' AS action, 
        GETDATE() AS action_date
    FROM INSERTED;
END;


--16. Display top n customers on the basis of transaction type.


CREATE PROCEDURE TopNCustomersByTransactionType (@p_txn_type VARCHAR(255), @p_n INT)
AS
BEGIN
    SELECT 
        t.customer_id, 
        SUM(t.txn_amount) AS total_amount
    FROM 
        [dbo].[Transaction] t
    WHERE 
        t.txn_type = @p_txn_type
    GROUP BY 
        t.customer_id
    ORDER BY 
        total_amount DESC
    OFFSET 0 ROWS
    FETCH NEXT @p_n ROWS ONLY;
END;


--17. Create a pivot table to display the total purchase, withdrawal and
--deposit for all the customers.

SELECT 
    customer_id,
    SUM(CASE WHEN txn_type = 'Purchase' THEN txn_amount ELSE 0 END) AS total_purchase,
    SUM(CASE WHEN txn_type = 'Withdrawal' THEN txn_amount ELSE 0 END) AS total_withdrawal,
    SUM(CASE WHEN txn_type = 'Deposit' THEN txn_amount ELSE 0 END) AS total_deposit
FROM 
    [dbo].[Transaction]
GROUP BY 
    customer_id;