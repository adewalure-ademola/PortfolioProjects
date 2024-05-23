-- Data cleaning in SQL

Select *
From
	PortfolioProject..NashvilleHousing


-----------------------------------------------
-- Standardize Data Format

Select 
	SaleDate,
	CONVERT(date, SaleDate)
From
	PortfolioProject..NashvilleHousing

Alter Table NashvilleHousing
Add SalesDateConverted date

Update NashvilleHousing
Set SalesDateConverted = CONVERT(date, SaleDate)



----------------------------------------------------------
--Populate Property Address Data
Select 
	*
From
	PortfolioProject..NashvilleHousing
Order By
	ParcelID

Select 
	a.ParcelID, 
	a.PropertyAddress,
	b.parcelID, 
	b.propertyAddress,
	isnull(a.PropertyAddress,b.PropertyAddress)
From
	PortfolioProject..NashvilleHousing a
	Join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
Where
	a.PropertyAddress is null

Update a
set PropertyAddress = isnull(a.PropertyAddress,'No Address')
From
	PortfolioProject..NashvilleHousing a
	Join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
Where
	a.PropertyAddress is null


-------------------------------------------------
-- Breaking out PropertyAddress with Substring


Select 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, len(PropertyAddress)) as State
From
	PortfolioProject..NashvilleHousing




Alter Table NashvilleHousing
Add  PropertySplitAddress nvarchar(255)

Update NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

Alter Table NashvilleHousing
Add PropertySplitCity nvarchar(255)

Update NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, len(PropertyAddress))

-- Breaking out OwnerAddress with ParseName
Select
	PARSENAME(replace(OwnerAddress, ',', '.'), 3),
	PARSENAME(replace(OwnerAddress, ',', '.'), 2),
	PARSENAME(replace(OwnerAddress, ',', '.'), 1)
From
	PortfolioProject..NashvilleHousing

Alter Table NashvilleHousing
Add  OwnerSplitAddress nvarchar(255)

Update NashvilleHousing
Set OwnerSplitAddress = PARSENAME(replace(OwnerAddress, ',', '.'), 3)

Alter Table NashvilleHousing
Add  OwnerSplitCity nvarchar(255)

Update NashvilleHousing
Set OwnerSplitCity = PARSENAME(replace(OwnerAddress, ',', '.'), 2)

Alter Table NashvilleHousing
Add  OwnerSplitState nvarchar(255)

Update NashvilleHousing
Set OwnerSplitState = PARSENAME(replace(OwnerAddress, ',', '.'), 1)



--------------------------------------------------
-- Change Y and N in "Sold as Vacant" field

Select 
	Distinct(SoldAsVacant),
	COUNT(SoldAsVacant)
From
	PortfolioProject..NashvilleHousing
Group By
	SoldAsVacant


Select
	SoldAsVacant,
	Case
		When SoldAsVacant = 'Y' Then 'Yes'
		When SoldAsVacant = 'N' Then 'No'
		Else SoldAsVacant
	End
From
	PortfolioProject..NashvilleHousing

Update NashvilleHousing
Set SoldAsVacant = Case
		When SoldAsVacant = 'Y' Then 'Yes'
		When SoldAsVacant = 'N' Then 'No'
		Else SoldAsVacant
	End

------------------------------------------------------
-- Remove Duplicates

With RowNumCTE as
(Select *,
	Row_Number() Over(
	Partition By ParcelID,
				PropertyAddress,
				SaleDate,
				LegalReference
				Order By
					UniqueID
					)row_num
From
	PortfolioProject..NashvilleHousing 
)
Delete
From
	RowNumCTE
Where row_num > 1


---------------------------------------------------
-- Delete Unused Columns

Alter Table PortfolioProject..NashvilleHousing
Drop Column OwnerAddress,TaxDistrict, PropertyAddress
