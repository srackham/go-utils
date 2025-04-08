package main

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func main() {
	r, err := CurrentExchangeRate("NZD")
	if err != nil {
		panic(err)
	}
	fmt.Printf("NZD: %#v\n", r)

	r, err = CurrentExchangeRate("AUD")
	if err != nil {
		panic(err)
	}
	fmt.Printf("AUD: %#v\n", r)

	r, err = CurrentExchangeRate("USD")
	if err != nil {
		panic(err)
	}
	fmt.Printf("USD: %#v\n", r)

	r, err = HistoricExchangeRate("NZD", "2022-06-01")
	if err != nil {
		panic(err)
	}
	fmt.Printf("NZD 2022-06-01: %#v\n", r)

	r, err = HistoricExchangeRate("AUD", "2022-06-01")
	if err != nil {
		panic(err)
	}
	fmt.Printf("AUD 2022-06-01: %#v\n", r)

	r, err = CurrentExchangeRate("NZD")
	if err != nil {
		panic(err)
	}
	fmt.Printf("NZD: %#v\n", r)

	r, err = CurrentExchangeRate("AUD")
	if err != nil {
		panic(err)
	}
	fmt.Printf("AUD: %#v\n", r)

	r, err = HistoricExchangeRate("NZD", "2022-06-01")
	if err != nil {
		panic(err)
	}
	fmt.Printf("NZD 2022-06-01: %#v\n", r)

	r, err = HistoricExchangeRate("AUD", "2022-06-01")
	if err != nil {
		panic(err)
	}
	fmt.Printf("AUD 2022-06-01: %#v\n", r)

	r, err = HistoricExchangeRate("USD", "2022-06-01")
	if err != nil {
		panic(err)
	}
	fmt.Printf("USD 2022-06-01: %#v\n", r)

	data, _ := json.Marshal(ratesCache)
	fmt.Println(string(data))

}

type rates map[string]float64 // Key = currency symbol; value = value in USD.

var ratesCache map[string]rates

func updateRatesCache(date string) (rates, error) {
	if ratesCache == nil {
		ratesCache = make(map[string]rates)
	}
	rates := make(rates)
	client := http.Client{}
	request, err := http.NewRequest("GET", fmt.Sprintf("https://api.exchangerate.host/%s", date), nil)
	if err != nil {
		return rates, err
	}
	resp, err := client.Do(request)
	if err != nil {
		return rates, err
	}
	var m map[string]any
	err = json.NewDecoder(resp.Body).Decode(&m)
	m = m["rates"].(map[string]any)
	for k, v := range m {
		rates[k] = v.(float64)
	}
	ratesCache[date] = rates
	return rates, nil
}

func CurrentExchangeRate(currency string) (float64, error) {
	return HistoricExchangeRate(currency, "latest")
}

func HistoricExchangeRate(currency string, date string) (float64, error) {
	var rates rates
	var ok bool
	var err error
	if rates, ok = ratesCache[date]; !ok {
		fmt.Println("UPDATING")
		rates, err = updateRatesCache(date)
		if err != nil {
			return 0.0, err
		}
	}
	if rate, ok := rates[currency]; !ok {
		return 0.0, fmt.Errorf("unknown currency: %s", currency)
	} else {
		return rate, nil
	}
}
