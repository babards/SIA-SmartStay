# 🌤️ Weather Data Verification Guide

## 📍 **Your Project Coordinates**
- **Location**: Malaybalay City, Bukidnon, Philippines
- **Latitude**: 8.1575° N
- **Longitude**: 125.1278° E
- **Timezone**: Asia/Manila (UTC+8)

### **Verify Coordinates**
You can verify these coordinates are correct by:
1. **Google Maps**: Search "Malaybalay City, Bukidnon, Philippines"
2. **OpenStreetMap**: https://www.openstreetmap.org/search?query=Malaybalay%20City%2C%20Bukidnon
3. **Coordinates Check**: The coordinates should point to the center of Malaybalay City

## 🔍 **Direct API Testing**

### **1. Current Weather API**
Copy and paste this URL in your browser to see the raw API response:

```
https://api.open-meteo.com/v1/forecast?latitude=8.1575&longitude=125.1278&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_direction_10m,weather_code,cloud_cover&timezone=Asia/Manila&timezone_abbreviation=PST
```

### **2. 7-Day Forecast API**
Copy and paste this URL in your browser to see the raw forecast data:

```
https://api.open-meteo.com/v1/forecast?latitude=8.1575&longitude=125.1278&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max,weather_code,precipitation_probability_max&timezone=Asia/Manila&timezone_abbreviation=PST&forecast_days=7
```

## 🛠️ **Testing Weather Data**

### **Step 1: Run Your App**
```bash
flutter run -d chrome
```

### **Step 2: Test Weather Popup**
- Login as a landlord
- Go to "Manage My Properties" screen
- Hover over a property marker on the map
- Check if weather data displays correctly

### **Step 3: Verify Weather Codes**
- Weather code 95 should show "Thunderstorm" with lightning bolt icon
- Weather code 3 should show "Overcast" with cloud icon
- Weather code 80 should show "Slight Rain Showers" with rain icon

## 📊 **Understanding Weather Codes**

Open-Meteo uses WMO (World Meteorological Organization) weather codes. Based on actual API testing with Malaybalay City, the following codes are confirmed:

| Code | Description | Your App Shows | Icon | Color |
|------|-------------|----------------|------|-------|
| 0 | Clear sky | Clear | ☀️ | Orange |
| 1 | Mainly clear | Mainly Clear | ⛅ | Light Blue |
| 2 | Partly cloudy | Partly Cloudy | ⛅ | Grey |
| 3 | Overcast | Overcast | ☁️ | Grey |
| 45, 48 | Fog | Fog | 🌫️ | Grey |
| 51, 53, 55 | Drizzle | Light/Moderate/Dense Drizzle | 🌧️ | Blue |
| 56, 57 | Freezing drizzle | Light/Dense Freezing Drizzle | 🌧️ | Blue |
| 61, 63, 65 | Rain | Slight/Moderate/Heavy Rain | 🌧️ | Blue |
| 66, 67 | Freezing rain | Light/Heavy Freezing Rain | 🌧️ | Blue |
| 71, 73, 75 | Snow | Slight/Moderate/Heavy Snow | ❄️ | Light Blue |
| 77 | Snow grains | Snow Grains | ❄️ | Light Blue |
| 80, 81, 82 | Rain showers | Slight/Moderate/Violent Rain Showers | 🌧️ | Blue |
| 85, 86 | Snow showers | Slight/Heavy Snow Showers | ❄️ | Light Blue |
| **95** | **Thunderstorm** | **Thunderstorm** | **⚡** | **Deep Orange** |
| **96** | **Thunderstorm with slight hail** | **Thunderstorm with Slight Hail** | **⚡** | **Deep Orange** |
| **99** | **Thunderstorm with heavy hail** | **Thunderstorm with Heavy Hail** | **⚡** | **Deep Orange** |

### **✅ Confirmed Weather Codes (from API testing):**
Based on actual Open-Meteo API testing with Malaybalay City coordinates (8.1575, 125.1278), the following weather codes were found:
- **Code 3**: Overcast (current weather)
- **Code 80**: Slight Rain Showers (forecast days 4-6)
- **Code 95**: Thunderstorm (forecast days 1, 2, 4)

### **⚠️ Important Note:**
The weather codes **95, 96, and 99** are **thunderstorms** and should display as "Thunderstorm" with a lightning bolt icon (⚡) and deep orange color. If your app shows "Clear" for these codes, there was a bug in the weather code interpretation (now fixed!).

## 🔄 **Comparing with Other Services**

### **AccuWeather**
- URL: https://www.accuweather.com/en/ph/malaybalay-city/2-262396_1_al/weather-forecast/2-262396_1_al
- Note: May show different values due to different data sources

### **Weather.com (The Weather Channel)**
- URL: https://weather.com/weather/today/l/8.1575,125.1278
- Alternative: https://weather.com/weather/tenday/l/ad0a220f26f6a66d2b465147fc55986e48e48d138342a600c5c660d66dca704f
- Note: Different forecasting models may produce different results

### **Weather-Forecast.com**
- URL: https://www.weather-forecast.com/locations/Malaybalay-City/forecasts/latest
- Note: Good for detailed forecasts and comparisons

### **Meteosource**
- URL: https://www.meteosource.com/current-weather-api-malaybalay
- Note: Professional weather API service

### **Meteoblue**
- URL: https://www.meteoblue.com/en/weather/week/malaybalay_philippines_1702934
- Note: European weather service with good accuracy

## ⚠️ **Why Weather Data May Differ**

### **1. Data Sources**
- **Open-Meteo**: Uses ECMWF (European Centre for Medium-Range Weather Forecasts)
- **AccuWeather**: Uses proprietary models and data sources
- **Weather.com**: Uses IBM Weather data

### **2. Update Frequency**
- **Open-Meteo**: Updates every 6 hours
- **Commercial services**: May update more frequently

### **3. Geographic Resolution**
- **Open-Meteo**: ~11km grid resolution
- **Commercial services**: May have higher resolution

### **4. Forecasting Models**
- Each service uses different algorithms
- Different models can produce different results

## 🧪 **Testing Steps**

### **1. Verify Coordinates**
```bash
# Check if coordinates are correct
echo "Malaybalay City: 8.1575, 125.1278"
```

### **2. Test API Response**
1. Open the API URL in browser
2. Check if response is valid JSON
3. Verify all required fields are present

### **3. Compare with Real Weather**
1. Check current weather outside
2. Compare with your app's data
3. Note any significant differences

### **4. Test Different Locations**
Try coordinates for other Bukidnon cities to verify accuracy:

#### **Valencia City**
- **Coordinates**: 7.9064, 125.0922
- **Current Weather API**: https://api.open-meteo.com/v1/forecast?latitude=7.9064&longitude=125.0922&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_direction_10m,weather_code,cloud_cover&timezone=Asia/Manila&timezone_abbreviation=PST

#### **Maramag**
- **Coordinates**: 7.7633, 125.0058
- **Current Weather API**: https://api.open-meteo.com/v1/forecast?latitude=7.7633&longitude=125.0058&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_direction_10m,weather_code,cloud_cover&timezone=Asia/Manila&timezone_abbreviation=PST

#### **Don Carlos**
- **Coordinates**: 7.6833, 125.0167
- **Current Weather API**: https://api.open-meteo.com/v1/forecast?latitude=7.6833&longitude=125.0167&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_direction_10m,weather_code,cloud_cover&timezone=Asia/Manila&timezone_abbreviation=PST

## 🧪 **Testing Weather Accuracy**

To verify weather data accuracy:

1. **Test the hover popup** on property markers
2. **Compare with other weather services** using the URLs provided
3. **Check weather codes** match the expected descriptions
4. **Verify coordinates** are correct for Malaybalay City

## 📱 **Mobile Testing**

For mobile testing, you can:
1. Test the hover popup on mobile devices
2. Check weather data accuracy on different screen sizes
3. Test with different device locations

## 🔧 **Troubleshooting**

### **If API returns errors:**
1. Check internet connection
2. Verify coordinates are valid
3. Check if Open-Meteo API is down

### **If data seems inaccurate:**
1. Compare with multiple weather services
2. Check if coordinates are correct
3. Verify timezone settings

### **If weather popup doesn't appear:**
1. Make sure you're hovering over a property marker on the map
2. Check if the property has valid coordinates
3. Verify internet connection for weather data

## 📞 **Support**

If you need help:
1. Test the hover popup functionality
2. Compare with the direct API URLs
3. Test with different coordinates
4. Verify with other weather services

Remember: Weather data accuracy can vary between services, and this is normal!
