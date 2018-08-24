                                 /*SAS CASE STUDY 2*/


/*Creating a library for SAS CASE STUDY 2*/
Libname cs2 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY';


/*Importing Different datasets for case study 2 into this library*/
Proc import datafile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\POS_Q1.csv'
dbms = csv
Out = cs2.POS_Q1;
getnames = yes;
Run;

Proc import datafile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\POS_Q2.csv'
dbms = csv
Out = cs2.POS_Q2;
getnames = yes;
Run;

Proc import datafile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\POS_Q3.csv'
dbms = csv
Out = cs2.POS_Q3;
getnames = yes;
Run;

Proc import datafile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\POS_Q4.csv'
dbms = csv
Out = cs2.POS_Q4;
getnames = yes;
Run;

Proc import datafile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\Laptops.csv'
dbms = csv
Out = cs2.Laptops;
getnames = yes;
Run;

Proc import datafile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\London_postal_codes.csv'
dbms = csv
Out = cs2.London_postal_codes;
getnames = yes;
Run;

Proc import datafile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\Store_locations.csv'
dbms = csv
Out = cs2.Store_loc;
getnames = yes;
Run;


/*Appending All POS datasets into one*/
Proc append base = cs2.Pos_q1 data = cs2.Pos_q2 force;
Run;

Proc append base = cs2.pos_q1 data = cs2.pos_q3 force;
Run;

Proc append base = cs2.pos_q1 data = cs2.pos_q4 force;
Run;


/*Creating a Final File by merging POS,Laptops,store post codes and london post codes*/
Proc sql;

Create table cs2.London_retail as

Select a.*,b.*

from cs2.pos as a right join cs2.Laptops as b
on a.configuration = b.configuration
;
Quit;


Proc sql;

Create table cs2.London_Laptop_retail as

Select a.*,b.*,c.Postcode as Customer_pcodes,c.os_x as customer_x,c.os_y as Customer_y,d.Postcode as Store_pcodes,d.os_x as Store_x,
d.os_y as Store_y,d.lat,d.long from cs2.POS as a

Right join  cs2.Laptops as b on a.configuration = b.configuration
Right join cs2.London_postal_codes as c on a.Customer_postcode=c.postcode
Right join cs2.Store_loc as d on a.store_postcode = d.postcode
;
Quit;

/*Exporting the final merged file London_laptop_retail to Excel file*/
Proc export data =cs2.london_laptop_retail
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
Run;


/*Creating a new variable called distance by calculating euclidian distance between store postal codes and customer postal codes*/
Data cs2.London_laptop_retail;
Set cs2.London_laptop_retail;

Distance = round(sqrt((Customer_x - Store_x)**2 + (Customer_y - Store_y)**2)/1000,0.1);
put Distance =;

Run;


/*(1) Analyzing if the laptop prices change with time*/
Proc sql;

Create table cs2.Change_in_price as

Select Configuration,Month,Round(Avg(Retail_Price)) as Average_Laptop_Price from cs2.London_laptop_retail
Group by Configuration,Month
Order by Configuration,Month,Average_laptop_price DESC;
Quit;

/*Exporting the dataset to excel for presentation purpose*/
Proc export data =cs2.Change_in_price
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
sheet = "Laptop_Price_with_Time";
Run;


/* (2) Analyzing if the prices over retail outlets consistent*/
Proc sql;

Create table cs2.Price_consistency as

Select store_pcodes as Stores,configuration,Month,Round(Avg(Retail_price),0.1) as Average_Laptop_Price
From cs2.London_laptop_retail

Group by stores,Month,Configuration
Order by configuration,month,Average_laptop_price DESC
;
Quit;


/*Exporting the data to excel*/
Proc export data =cs2.Price_consistency
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
sheet = "Price_Consistency_over_Stores";
Run;


/*(3) Analyzing how does price changes with configuration*/
Proc sql;

Create table cs2.price_config as

Select Month,Configuration,Round(avg(retail_price)) as Laptop_price from cs2.london_laptop_retail
Group by Month,Configuration
Order by Month,Configuration
;
Quit;

/*Exporting the data to excel*/
Proc export data =cs2.price_config
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
sheet = "Price_change_with_configuration";
Run;




         /*Checking on how location is influencing sales*/

/*(4).Checking Where are the stores and customers located*/
Proc sql;

Create table cs2.cust_store_loc as

Select Avg(Distance) as Average_distance,Count(Retail_price) as Customers_Visiting_Store
,Sum(Retail_price) as Total_sales
from cs2.london_laptop_retail

Group by distance
;
Quit;

Proc sql;

Create table cs2.cust_store_loc2 as

Select *,Total_sales/Sum(Total_sales) as Proportion_of_sales format = percent8.2,
Customers_visiting_store/sum(Customers_Visiting_Store) as proportion_of_volume format = percent8.2
from cs2.cust_store_loc
Order by Average_distance,Total_sales DESC;

Quit;

/*Exporting the data to excel*/
Proc export data =cs2.cust_store_loc2
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
sheet = "Customers & Stores Distance ";
Run;


/*(5).Finding out which Stores are selling most*/
Proc sql;

Create table cs2.Top_sellers as

Select Distinct store_postcode as Stores,Sum(retail_price) as Total_sales,
Round((Sum(retail_price)/(Select sum(Retail_price) from cs2.london_laptop_retail)),0.01) as Sales_Contribution
Format = percent8.2

from cs2.london_laptop_retail

Group by Stores
Order by Total_sales DESC
;
Quit;

/*Exporting the data to excel*/
Proc export data =cs2.Top_sellers
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
sheet = "Top sellers";
Run;


/*(6).How Far customers would travel to buy laptop*/
Proc sql;

Create table cs2.Cust_travels as

Select Store_postcode as Stores,Avg(Distance) as Distance_Travelled,Count(Retail_price) as Customers_Count,
sum(Retail_price) as Total_sales

from cs2.london_laptop_retail

Group by distance,stores
Order by Stores,distance DESC
;
Quit;


Proc sql;

Create table cs2.cust_travels2 as

Select *,Customers_Count/Sum(customers_count) as Customers_Volume format = percent8.2,
Total_sales/Sum(Total_sales) as Sales_Percentage format = percent8.2

from cs2.cust_travels

Group by Stores
Order by stores,customers_count DESC
;
Quit;

/*Exporting the data to excel*/
Proc export data =cs2.cust_travels2
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
sheet = "distance travelled by customers";
Run;


/*(7).Find the details of each configuration,and how does it relate to the price*/
/*Creating Appropriate Formats for the configuration Details*/
Proc format;

Value Scnfmt

15 = "Low Size"
17 = "High Size"
;

Value Battfmt
4 = "Low Battery Life"
5 = "Medium Battery Life"
6 = "High Battery Life"
;

Value RAMfmt
1 = "Low Ram"
2 = "Medum Ram"
4 = "High Ram"
;

Value Procfmt
1.5 = "Low Processor"
2 = "Medium Processor"
2.4 = "High Processor"
;

Value hdfmt
40 = "Very Low HD"
80 = "Low HD"
120 = "Medium HD"
300 = "High HD"
;
Run;


/*Creating a dataset with configuration details and sales*/
Proc sql;

Create table cs2.config_price as

Select Configuration as Models,Screen_size__Inches_ as Screen_Size,Battery_Life__Hours_ as Battery_Life
,RAM__GB_ as RAM,Processor_Speeds__GHz_ as Processor,Integrated_Wireless_ as Wireless,HD_Size__GB_ as HD_size,
Bundled_Applications_ as Application_Bundling,Round(sum(Retail_price)) as Total_Sales,Count(Retail_price) as Cust_Volume,
Round(avg(Retail_price)) as Price

from cs2.london_laptop_retail

Group by Models,Screen_size,Battery_Life,RAM,Processor,Wireless,HD_size,Application_Bundling
Order by Models,Screen_size,Battery_Life,RAM,Processor,Wireless,HD_size,Application_Bundling,Total_sales DESC
;
Quit;

Proc sql;

Create table cs2.Config_price2 as

Select *,(Total_sales/Sum(Total_sales)) as Sales_Proportion format = percent8.2
,(cust_volume/sum(cust_volume)) as Customer_Volume_Proportion format = percent8.2

from cs2.config_price
;
Quit;

/*Applying the format*/
data cs2.config_price;
set cs2.config_price;
format Screen_Size Scnfmt.;
format Battery_life battfmt.;
format RAM ramfmt.;
format processor procfmt.;
format hd_size hdfmt.;

Run;


/*Exporting the data to excel*/
Proc export data =cs2.config_price2
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
sheet = "Configuration Details & price";
Run;


/*(8).Finding if all the stores sell all the configuration models*/
Proc sql;

Create table cs2.Stores_andModels as

Select Store_postcode as Store,Configuration as Models,Count(Configuration) as Total_models_Sold from cs2.london_laptop_retail
Group by store,models
Order by Store,total_models_Sold DESC
;
Quit;

Proc export data =cs2.Stores_andModels
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
sheet = "Stores and Models Sold";
Run;


                             /*Finding how revenue is influenced by different factors*/

/*(9).Finding how the sales volume in each store relate to company's revenues?*/
Proc sql;

create table cs2.Vol_Revenue as

Select store_postcode as Stores,Count(retail_price) as Volume,Sum(retail_price) as Revenue
from cs2.london_laptop_retail
Group by store_postcode;

Quit;


/*Calculating proportions for Revenue & Volume*/
Proc sql;

create table cs2.Vol_Rev2 as

select * , Volume/sum(Volume) as proportion_of_volume format = percent8.2,
revenue /sum(revenue) as proportion_of_revenue format = percent8.2
from cs2.Vol_Revenue

order by Volume desc;

Quit;


Proc sql;

create table cs2.Sales_and_Revenue as

select distinct(a.stores),a.volume,a.revenue,a.proportion_of_volume,

sum(b.proportion_of_volume) as cum_volume format = percent8.2,
a.proportion_of_revenue,sum(b.proportion_of_revenue) as cum_revenue format = percent8.2

from cs2.Vol_Rev2 as a INNER join  cs2.Vol_rev2 as b

on b.Stores<=a.Stores
group by a.stores
order by a.stores;

Quit;


/*Exporting data Sales_and_Revenue to excel*/
Proc export data =cs2.Sales_and_Revenue
outfile = 'C:\Users\Aditya\Desktop\SAS CASE STUDIES\SAS Case study 2 files\CASE STUDY\SAS CS2.xls'
dbms = excel replace;
sheet = "Sales,Revenue & Price ";
Run;


/**END**/
