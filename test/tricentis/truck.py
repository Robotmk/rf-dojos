from .base import PageObject


class Truck(PageObject):
    def enter_vehicle_data(
        self,
        make: str,
        power_kw: str,
        manufacture_date: str,
        seats: str,
        fuel_type: str,
        payload_kg: str,
        total_weight_kg: str,
        list_price: str,
        license_plate: str,
        annual_mileage: str,
    ) -> None:
        self._page_title_should_be("Enter Vehicle Data")
        self._select_by_label("#make", make)
        self._fill("#engineperformance", power_kw)
        self._fill("#dateofmanufacture", manufacture_date)
        self._select_by_label("#numberofseats", seats)
        self._select_by_label("#fuel", fuel_type)
        self._fill("#payload", payload_kg)
        self._fill("#totalweight", total_weight_kg)
        self._fill("#listprice", list_price)
        self._fill("#licenseplatenumber", license_plate)
        self._fill("#annualmileage", annual_mileage)
        self._click("#nextenterinsurantdata")
