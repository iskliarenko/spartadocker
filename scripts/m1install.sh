#!/bin/bash

CNF=~/.m1install.conf

source $CNF

# Var
branch=$1
clone=$2

#Git operations
echo -e "* Git operations"

if [[ "$branch" != '' ]]
then
	if [ "$clone" != "" ] && [ "$clone" == 'clone' ]
	then

		origin='git@github.com:magento-sparta/magento1.git'
		git clone $origin .
	else
		echo -e "   - git reset"
		git reset --hard HEAD &> /dev/null
		if [[ "$branch" != *'v1.1'* ]]
		then
			echo -e "   - git pull\n"
			git pull
		fi
	fi
	echo -e "   - git checkout"
	git checkout -f "$branch" &> /dev/null
fi

#Clean var/ and recreate database
if [ -a app/etc/local.xml ]
then
	echo "* Remove local.xml"
	rm app/etc/local.xml
fi

echo "* Remove var/*"
rm -rf var/*
echo "* Recreate database"
mysql_querry="drop database if exists $mysql_db_name; create database $mysql_db_name;"

if [[ $mysql_password == '' ]]
then
	execute_mysql="$mysql_path -h $mysql_host -u $mysql_user -e '$mysql_querry'"
else
	execute_mysql="$mysql_path -h $mysql_host -u $mysql_user -p $mysql_password -e '$mysql_querry'"
fi
eval $execute_mysql

# Reinstall Magento
echo -e "* Reinstall Magento \n"
if [ -a install.php ]
then
	php install.php --skip_url_validation --license_agreement_accepted "yes" --locale "en_US" --timezone "America/Los_Angeles" --default_currency "USD" --db_host "$mysql_host" --db_name "$mysql_db_name" --db_user "$mysql_user" --url "$base_url" --use_rewrites "yes" --use_secure "no" --secure_base_url "" --use_secure_admin "no" --admin_firstname "joe" --admin_lastname "doe" --admin_email "admin@example.com" --admin_username "admin" --admin_password "123123q"
else
	echo -e "\nError:  required file missing install.php"
fi

# Add sample data
echo -e "\n* Adding sample data "
if [ -a app/Mage.php ]
then
PHP_CODE="
require_once 'app/Mage.php';
Mage::app()->setCurrentStore(Mage_Core_Model_App::ADMIN_STORE_ID);

\$category = Mage::getModel('catalog/category');
\$category->setStoreId(0);

\$general['name'] = \"anchor category\";
\$general['path'] = \"1/2\";
\$general['display_mode'] = \"PRODUCTS_AND_PAGE\";
\$general['is_active'] = 1;
\$general['is_anchor'] = 1;
\$category->addData(\$general);

try {
    \$category->save();
}
catch (Exception \$e){
    echo \$e->getMessage();
}

for (\$i = 1; \$i <= 20; \$i++) {
	\$product = Mage::getModel('catalog/product');
	try{
		\$product_id = \$i;
		\$product
		->setWebsiteIds(array(1)) //website ID the product is assigned to
		->setAttributeSetId(4) //ID of a attribute set named 'default'
		->setTypeId('simple')
		->setCreatedAt(strtotime('now'))
		->setSku(\"sku_\$product_id\")
		->setName(\"simple_\$product_id\")
		->setWeight(0.1000)
		->setStatus(1)
		->setTaxClassId(4) //tax class (0 - none, 1 - default, 2 - taxable, 4 - shipping)
		->setVisibility(Mage_Catalog_Model_Product_Visibility::VISIBILITY_BOTH)
		->setPrice(10 * \$product_id)
		->setDescription('This is a long description')
		->setShortDescription('This is a short description')
		->setStockData(array(
            'use_config_manage_stock' => 0,
            'manage_stock'=>1,
            'is_in_stock' => 1,
            'qty' => 1000
			)
		)
		->setCategoryIds(array(\$category->getId()))
		->save();
	} catch(Exception \$e){
		echo \$e->getMessage();
	}
}

\$customer = Mage::getModel(\"customer/customer\");
\$customer   ->setWebsiteId(1)
			->setCurrentStore(1)
            ->setFirstname('John')
            ->setLastname('Doe')
            ->setEmail('test@example.com')
            ->setPassword('123123q');

try{
    \$customer->save();
}
catch (Exception \$e) {
    echo \$e->getMessage();
}
\$address = Mage::getModel(\"customer/address\");
\$address->setCustomerId(\$customer->getId())
        ->setFirstname(\$customer->getFirstname())
        ->setMiddleName(\$customer->getMiddlename())
        ->setLastname(\$customer->getLastname())
        ->setCountryId('US')
		->setRegionId('12')
        ->setPostcode('90232')
        ->setCity('Culver city')
        ->setTelephone('0038511223344')
        ->setFax('0038511223355')
        ->setCompany('Magento')
        ->setStreet('10441 Jefferson Blvd')
        ->setIsDefaultBilling('1')
        ->setIsDefaultShipping('1')
        ->setSaveInAddressBook('1');

try{
    \$address->save();
}
catch (Exception \$e) {
    echo \$e->getMessage();
}
"
php -r "$PHP_CODE"
else
	echo -e "\nError: required file missing app/Mage.php \n"
fi

echo "* Done"
