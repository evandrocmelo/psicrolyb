' PsychroLib (version 2.0.0) (https://github.com/psychrometrics/psychrolib)
' Copyright (c) 2018 D. Thevenard and D. Meyer for the current library implementation
' Copyright (c) 2017 ASHRAE Handbook — Fundamentals for ASHRAE equations and coefficients
' Licensed under the MIT License.
'
' psychrolib.vba
'
' Contains functions for calculating thermodynamic properties of gas-vapor mixtures
' and standard atmosphere suitable for most engineering, physical and meteorological
' applications.
'
' Most of the functions are an implementation of the formulae found in the
' 2017 ASHRAE Handbook - Fundamentals, in both International System (SI),
' and Imperial (IP) units. Please refer to the information included in
' each function for their respective reference.
'
' Example
'     ' Set the unit system, for example to SI (can be either ' SI'  or ' IP' )
'     ' by uncommenting the following line in the psychrolib module
'     Const PSYCHROLIB_UNITS = UnitSystem.SI
'
'     ' Calculate the dew point temperature for a dry bulb temperature of 25 C and a relative humidity of 80%
'     TDewPoint = GetTDewPointFromRelHum(25.0, 0.80)
'     Debug.Print(TDewPoint)
'     21.309397163661785
'
' Copyright
'     - For the current library implementation
'         Copyright (c) 2018 D. Thevenard and D. Meyer.
'     - For equations and coefficients published ASHRAE Handbook — Fundamentals, Chapter 1
'         Copyright (c) 2017 ASHRAE Handbook — Fundamentals (https://www.ashrae.org)
'
' License
'     MIT (https://github.com/psychrometrics/psychrolib/LICENSE.txt)
'
' Note from the Authors
'     We have made every effort to ensure that the code is adequate, however, we make no
'     representation with respect to its accuracy. Use at your own risk. Should you notice
'     an error, or if you have a suggestion, please notify us through GitHub at
'     https://github.com/psychrometrics/psychrolib/issues.
'

Option Explicit


'******************************************************************************************************
' IMPORTANT: Manually uncomment the system of units to use
'******************************************************************************************************

'Enumeration to define systems of units
Enum UnitSystem
  IP = 1
  SI = 2
End Enum

' Uncomment one of these two lines to define the system of units ("IP" or "SI")
'Const PSYCHROLIB_UNITS = UnitSystem.IP
'Const PSYCHROLIB_UNITS = UnitSystem.SI


'******************************************************************************************************
' Global constants
'******************************************************************************************************

Private Const R_DA_IP = 53.35               ' Universal gas constant for dry air (IP version) in ft lbf/lb_DryAir/R
Private Const R_DA_SI = 287.042             ' Universal gas constant for dry air (SI version) in J/kg_DryAir/K


'******************************************************************************************************
' Helper functions
'******************************************************************************************************

Function GetUnitSystem() As UnitSystem
'
' This function returns the system of units currently in use (SI or IP).
'
' Args:
'        none
'
' Returns:
'        The system of units currently in use ('SI' or 'IP')
'
' Note:
'
'        If you get an error here, it's because you have not uncommented one of the two lines
'        defining PSYCHROLIB_UNITS (see Global Constants section)
'
    GetUnitSystem = PSYCHROLIB_UNITS

End Function

Private Function isIP() As Variant
'
' This function checks whether the system of units currently in use is IP or SI.
'
' Args:
'         none
'
' Returns:
'         True if IP, False if SI, and raises error if undefined
'
  If (PSYCHROLIB_UNITS = UnitSystem.IP) Then
    isIP = True
  ElseIf (PSYCHROLIB_UNITS = UnitSystem.SI) Then
    isIP = False
  Else
    MsgBox ("The system of units has not been defined.")
    isIP = CVErr(xlErrNA)
  End If

End Function

Private Function GetTol() As Variant
'
' This function returns the tolerance on temperatures used for iterative solving.
' The value is physically the same in IP or SI.
'
' Args:
'         none
'
' Returns:
'         Tolerance on temperatures
'
  If (PSYCHROLIB_UNITS = UnitSystem.IP) Then
    GetTol = 0.001 * 9 / 5
  Else
    GetTol = 0.001
  End If
End Function

Private Sub MyMsgBox(ByVal ErrMsg As String)
'
' Error message output
' Override this function with your own if needed, or comment its code out if you don't want to see the messages
'
' Message disabled by default
'  MsgBox (ErrMsg)

End Sub

Private Function Min(ByVal Num1 As Variant, ByVal Num2 As Variant) As Variant
'
' Min function to return minimum of two numbers
'
  If (Num1 <= Num2) Then
    Min = Num1
  Else
    Min = Num2
  End If

End Function

Private Function Max(ByVal Num1 As Variant, ByVal Num2 As Variant) As Variant
'
' Max function to return maximum of two numbers
'
  If (Num1 >= Num2) Then
    Max = Num1
  Else
    Max = Num2
  End If

End Function


'*****************************************************************************
' Conversions between temperature units
'*****************************************************************************

Function GetTRankineFromTFahrenheit(ByVal T_Fahrenheit As Variant) As Variant
'
' Utility function to convert temperature to degree Rankine (°R)
' given temperature in degree Fahrenheit (°F).
'
'Args:
'        TRankine: Temperature in degree Fahrenheit (°F)
'
'Returns:
'        Temperature in degree Rankine (°R)
'
'Notes:
'        Exact conversion.
'
  On Error GoTo ErrHandler

  GetTRankineFromTFahrenheit = (T_Fahrenheit + 459.67)
  Exit Function

ErrHandler:
  GetTRankineFromTFahrenheit = CVErr(xlErrNA)

End Function

Function GetTKelvinFromTCelsius(ByVal T_Celsius As Variant) As Variant
'
' Utility function to convert temperature to Kelvin (K)
' given temperature in degree Celsius (°C).
'
'Args:
'        TCelsius: Temperature in degree Celsius (°C)
'
'Returns:
'        Temperature in Kelvin (K)
'
'Notes:
'        Exact conversion.
'
  On Error GoTo ErrHandler

  GetTKelvinFromTCelsius = (T_Celsius + 273.15)
  Exit Function

ErrHandler:
  GetTKelvinFromTCelsius = CVErr(xlErrNA)

End Function


'******************************************************************************************************
' Conversions between dew point, wet bulb, and relative humidity
'******************************************************************************************************

Function GetTWetBulbFromTDewPoint(ByVal TDryBulb As Variant, ByVal TDewPoint As Variant, ByVal Pressure As Variant) As Variant
'
' Return wet-bulb temperature given dry-bulb temperature, dew-point temperature, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        TDewPoint : Dew-point temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Wet-bulb temperature in °F [IP] or °C [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
  Dim HumRatio As Variant

  On Error GoTo ErrHandler

  If TDewPoint > TDryBulb Then
    MyMsgBox ("Dew point temperature is above dry bulb temperature")
    GoTo ErrHandler
  End If

  HumRatio = GetHumRatioFromTDewPoint(TDewPoint, Pressure)
  GetTWetBulbFromTDewPoint = GetTWetBulbFromHumRatio(TDryBulb, HumRatio, Pressure)
  Exit Function

ErrHandler:
  GetTWetBulbFromTDewPoint = CVErr(xlErrNA)

End Function

Function GetTWetBulbFromRelHum(ByVal TDryBulb As Variant, ByVal RelHum As Variant, ByVal Pressure As Variant) As Variant
'
' Return wet-bulb temperature given dry-bulb temperature, relative humidity, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        RelHum : Relative humidity in range [0, 1]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Wet-bulb temperature in °F [IP] or °C [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
  Dim HumRatio As Variant

  On Error GoTo ErrHandler

  If (RelHum < 0 Or RelHum > 1) Then
    MyMsgBox ("Relative humidity is outside range [0,1]")
    GoTo ErrHandler
  End If

  HumRatio = GetHumRatioFromRelHum(TDryBulb, RelHum, Pressure)
  GetTWetBulbFromRelHum = GetTWetBulbFromHumRatio(TDryBulb, HumRatio, Pressure)
  Exit Function

ErrHandler:
  GetTWetBulbFromRelHum = CVErr(xlErrNA)

End Function

Function GetRelHumFromTDewPoint(ByVal TDryBulb As Variant, ByVal TDewPoint As Variant) As Variant
'
' Return relative humidity given dry-bulb temperature and dew-point temperature.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        TDewPoint : Dew-point temperature in °F [IP] or °C [SI]
'
' Returns:
'        Relative humidity in range [0, 1]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 22
'
  Dim VapPres As Variant
  Dim SatVapPres As Variant

  On Error GoTo ErrHandler

  If (TDewPoint > TDryBulb) Then
    MyMsgBox ("Dew point temperature is above dry bulb temperature")
    GoTo ErrHandler
  End If

  VapPres = GetSatVapPres(TDewPoint)
  SatVapPres = GetSatVapPres(TDryBulb)
  GetRelHumFromTDewPoint = VapPres / SatVapPres
  Exit Function

ErrHandler:
  GetRelHumFromTDewPoint = CVErr(xlErrNA)

End Function

Function GetRelHumFromTWetBulb(ByVal TDryBulb As Variant, ByVal TWetBulb As Variant, ByVal Pressure As Variant) As Variant
'
' Return relative humidity given dry-bulb temperature, wet bulb temperature and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        TWetBulb : Wet-bulb temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Relative humidity in range [0, 1]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
  Dim HumRatio As Variant

  On Error GoTo ErrHandler

  If TWetBulb > TDryBulb Then
    MyMsgBox ("Wet bulb temperature is above dry bulb temperature")
    GoTo ErrHandler
  End If

  HumRatio = GetHumRatioFromTWetBulb(TDryBulb, TWetBulb, Pressure)
  GetRelHumFromTWetBulb = GetRelHumFromHumRatio(TDryBulb, HumRatio, Pressure)
  Exit Function

ErrHandler:
  GetRelHumFromTWetBulb = CVErr(xlErrNA)

End Function

Function GetTDewPointFromRelHum(ByVal TDryBulb As Variant, ByVal RelHum As Variant) As Variant
'
' Return dew-point temperature given dry-bulb temperature and relative humidity.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        RelHum: Relative humidity in range [0, 1]
'
' Returns:
'        Dew-point temperature in °F [IP] or °C [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'

  Dim VapPres As Variant

  On Error GoTo ErrHandler

  If RelHum < 0 Or RelHum > 1 Then
    MyMsgBox ("Relative humidity is outside range [0, 1]")
    GoTo ErrHandler
  End If

  VapPres = GetVapPresFromRelHum(TDryBulb, RelHum)
  GetTDewPointFromRelHum = GetTDewPointFromVapPres(TDryBulb, VapPres)
  Exit Function

ErrHandler:
  GetTDewPointFromRelHum = CVErr(xlErrNA)

End Function

Function GetTDewPointFromTWetBulb(ByVal TDryBulb As Variant, ByVal TWetBulb As Variant, ByVal Pressure As Variant) As Variant
'
' Return dew-point temperature given dry-bulb temperature, wet-bulb temperature, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        TWetBulb : Wet-bulb temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Dew-point temperature in °F [IP] or °C [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
  Dim HumRatio As Variant

  On Error GoTo ErrHandler

  If TWetBulb > TDryBulb Then
    MyMsgBox ("Wet bulb temperature is above dry bulb temperature")
    GoTo ErrHandler
  End If

  HumRatio = GetHumRatioFromTWetBulb(TDryBulb, TWetBulb, Pressure)
  GetTDewPointFromTWetBulb = GetTDewPointFromHumRatio(TDryBulb, HumRatio, Pressure)
  Exit Function

ErrHandler:
  GetTDewPointFromTWetBulb = CVErr(xlErrNA)

End Function


'******************************************************************************************************
'  Conversions between dew point, or relative humidity and vapor pressure
'******************************************************************************************************

Function GetVapPresFromRelHum(ByVal TDryBulb As Variant, ByVal RelHum As Variant) As Variant
'
' Return partial pressure of water vapor as a function of relative humidity and temperature.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        RelHum : Relative humidity in range [0, 1]
'
' Returns:
'        Partial pressure of water vapor in moist air in Psi [IP] or Pa [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 12, 22
'
  On Error GoTo ErrHandler

  If RelHum < 0 Or RelHum > 1 Then
    MyMsgBox ("Relative humidity is outside range [0, 1]")
    GoTo ErrHandler
  End If

  GetVapPresFromRelHum = RelHum * GetSatVapPres(TDryBulb)
  Exit Function

ErrHandler:
  GetVapPresFromRelHum = CVErr(xlErrNA)

End Function

Function GetRelHumFromVapPres(ByVal TDryBulb As Variant, ByVal VapPres As Variant) As Variant
' Return relative humidity given dry-bulb temperature and vapor pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        VapPres: Partial pressure of water vapor in moist air in Psi [IP] or Pa [SI]
'
' Returns:
'        Relative humidity in range [0, 1]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 12, 22
'
  On Error GoTo ErrHandler

  If (VapPres < 0) Then
    MyMsgBox ("Partial pressure of water vapor in moist air is negative")
    GoTo ErrHandler
  End If

  GetRelHumFromVapPres = VapPres / GetSatVapPres(TDryBulb)
  Exit Function

ErrHandler:
  GetRelHumFromVapPres = CVErr(xlErrNA)

End Function

Function GetTDewPointFromVapPres(ByVal TDryBulb As Variant, ByVal VapPres As Variant) As Variant
'
' Return dew-point temperature given dry-bulb temperature and vapor pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        VapPres: Partial pressure of water vapor in moist air in Psi [IP] or Pa [SI]
'
' Returns:
'        Dew-point temperature in °F [IP] or °C [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn. 5 and 6
'
' Notes:
'        The dew point temperature is solved by inverting the equation giving water vapor pressure
'        at saturation from temperature rather than using the regressions provided
'        by ASHRAE (eqn. 37 and 38) which are much less accurate and have a
'        narrower range of validity.
'        The Newton-Raphson (NR) method is used on the logarithm of water vapour
'        pressure as a function of temperature, which is a very smooth function
'        Convergence is usually achieved in 3 to 5 iterations.
'        TDryBulb is not really needed here, just used for convenience.
'
  Dim BOUNDS_(2) As Variant
  Dim STEPSIZE_ As Variant
  If (isIP()) Then
    BOUNDS_(1) = -148
    BOUNDS_(2) = 392
    STEPSIZE_ = 0.01 * 9 / 5
  Else
    BOUNDS_(1) = -100
    BOUNDS_(2) = 200
    STEPSIZE_ = 0.01
  End If

  Dim TMidPoint As Variant
  TMidPoint = (BOUNDS_(1) + BOUNDS_(2)) / 2#      ' Midpoint of domain of validity

  On Error GoTo ErrHandler

  If ((VapPres < GetSatVapPres(BOUNDS_(1))) Or (VapPres > GetSatVapPres(BOUNDS_(2)))) Then
    MyMsgBox ("Partial pressure of water vapor is outside range of validity of equations")
    GoTo ErrHandler
  End If

  ' First guess
  Dim TDewPoint As Variant
  Dim lnVP As Variant
  Dim d_lnVP As Variant
  Dim TDewPoint_iter As Variant
  Dim StepSize As Variant
  Dim lnVP_iter
  TDewPoint = TDryBulb        ' Calculated value of dew point temperatures, solved for iteratively
  Dim Tol As Variant

  lnVP = Log(VapPres)          ' Partial pressure of water vapor in moist air

  Tol = GetTol()
  Do
    TDewPoint_iter = TDewPoint   ' Value of Tdp used in NR calculation

    ' Step - negative in the right part of the curve, positive in the left part
    ' to avoid going past the domain of validity of eqn. 5 and 6
    ' when TDewPoint_iter is close to its bounds
    If (TDewPoint_iter > TMidPoint) Then
        StepSize = -STEPSIZE_
      Else
        StepSize = STEPSIZE_
    End If

    lnVP_iter = Log(GetSatVapPres(TDewPoint_iter))
    ' Derivative of function, calculated numerically
    d_lnVP = (Log(GetSatVapPres(TDewPoint_iter + StepSize)) - lnVP_iter) / StepSize
    ' New estimate, bounded by domain of validity of eqn. 5 and 6
    TDewPoint = TDewPoint_iter - (lnVP_iter - lnVP) / d_lnVP
    TDewPoint = Max(TDewPoint, BOUNDS_(1))
    TDewPoint = Min(TDewPoint, BOUNDS_(2))

  Loop While (Abs(TDewPoint - TDewPoint_iter) > Tol)

  TDewPoint = Min(TDewPoint, TDryBulb)
  GetTDewPointFromVapPres = TDewPoint
  Exit Function

ErrHandler:
  GetTDewPointFromVapPres = CVErr(xlErrNA)

End Function

Function GetVapPresFromTDewPoint(ByVal TDewPoint As Variant) As Variant
'
' Return vapor pressure given dew point temperature.
'
' Args:
'        TDewPoint : Dew-point temperature in °F [IP] or °C [SI]
'
' Returns:
'        Partial pressure of water vapor in moist air in Psi [IP] or Pa [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 36
'
  On Error GoTo ErrHandler
  GetVapPresFromTDewPoint = GetSatVapPres(TDewPoint)
  Exit Function

ErrHandler:
  GetVapPresFromTDewPoint = CVErr(xlErrNA)

End Function


'******************************************************************************************************
'  Conversions from wet-bulb temperature, dew-point temperature, or relative humidity to humidity ratio
'******************************************************************************************************

Function GetTWetBulbFromHumRatio(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
'
' Return wet-bulb temperature given dry-bulb temperature, humidity ratio, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        HumRatio : Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Wet-bulb temperature in °F [IP] or °C [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 33 and 35 solved for Tstar
'

  ' Declarations
  Dim Wstar As Variant
  Dim TDewPoint As Variant, TWetBulb As Variant, TWetBulbSup As Variant, TWetBulbInf As Variant
  Dim Tol As Variant

  On Error GoTo ErrHandler

  If HumRatio < 0 Then
    MyMsgBox ("Humidity ratio cannot be negative")
    GoTo ErrHandler
  End If

  TDewPoint = GetTDewPointFromHumRatio(TDryBulb, HumRatio, Pressure)

  ' Initial guesses
  TWetBulbSup = TDryBulb
  TWetBulbInf = TDewPoint
  TWetBulb = (TWetBulbInf + TWetBulbSup) / 2

  ' Bisection loop
  Tol = GetTol()
  While (TWetBulbSup - TWetBulbInf > Tol)

   ' Compute humidity ratio at temperature Tstar
   Wstar = GetHumRatioFromTWetBulb(TDryBulb, TWetBulb, Pressure)

   ' Get new bounds
   If (Wstar > HumRatio) Then
    TWetBulbSup = TWetBulb
   Else
    TWetBulbInf = TWetBulb
   End If

   ' New guess of wet bulb temperature
   TWetBulb = (TWetBulbSup + TWetBulbInf) / 2

  Wend

  GetTWetBulbFromHumRatio = TWetBulb
  Exit Function

ErrHandler:
  GetTWetBulbFromHumRatio = CVErr(xlErrNA)

End Function

Function GetHumRatioFromTWetBulb(ByVal TDryBulb As Variant, ByVal TWetBulb As Variant, ByVal Pressure As Variant) As Variant
'
' Return humidity ratio given dry-bulb temperature, wet-bulb temperature, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        TWetBulb : Wet-bulb temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 33 and 35

  Dim Wsstar As Variant
  Wsstar = GetSatHumRatio(TWetBulb, Pressure)

  On Error GoTo ErrHandler

  If TWetBulb > TDryBulb Then
    MyMsgBox ("Wet bulb temperature is above dry bulb temperature")
    GoTo ErrHandler
  End If

  If isIP() Then
    If (TWetBulb >= 32) Then
      GetHumRatioFromTWetBulb = ((1093 - 0.556 * TWetBulb) * Wsstar - 0.24 * (TDryBulb - TWetBulb)) / (1093 + 0.444 * TDryBulb - TWetBulb)
    Else
      GetHumRatioFromTWetBulb = ((1220 - 0.04 * TWetBulb) * Wsstar - 0.24 * (TDryBulb - TWetBulb)) / (1220 + 0.444 * TDryBulb - 0.48 * TWetBulb)
    End If
  Else
    If (TWetBulb >= 0) Then
      GetHumRatioFromTWetBulb = ((2501 - 2.326 * TWetBulb) * Wsstar - 1.006 * (TDryBulb - TWetBulb)) / (2501 + 1.86 * TDryBulb - 4.186 * TWetBulb)
    Else
      GetHumRatioFromTWetBulb = ((2830# - 0.24 * TWetBulb) * Wsstar - 1.006 * (TDryBulb - TWetBulb)) / (2830# + 1.86 * TDryBulb - 2.1 * TWetBulb)
    End If
  End If
  Exit Function

ErrHandler:
  GetHumRatioFromTWetBulb = CVErr(xlErrNA)

End Function

Function GetHumRatioFromRelHum(ByVal TDryBulb As Variant, ByVal RelHum As Variant, ByVal Pressure As Variant) As Variant
'
' Return humidity ratio given dry-bulb temperature, relative humidity, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        RelHum : Relative humidity in range [0, 1]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
  Dim VapPres As Variant

  On Error GoTo ErrHandler

  If RelHum < 0 Or RelHum > 1 Then
    MyMsgBox ("Relative humidity is outside range [0, 1]")
    GoTo ErrHandler
  End If

  VapPres = GetVapPresFromRelHum(TDryBulb, RelHum)
  GetHumRatioFromRelHum = GetHumRatioFromVapPres(VapPres, Pressure)
  Exit Function

ErrHandler:
  GetHumRatioFromRelHum = CVErr(xlErrNA)

End Function

Function GetRelHumFromHumRatio(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
'
'    Return relative humidity given dry-bulb temperature, humidity ratio, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        HumRatio : Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Relative humidity in range [0, 1]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
  Dim VapPres As Variant

  On Error GoTo ErrHandler

  If HumRatio < 0 Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  VapPres = GetVapPresFromHumRatio(HumRatio, Pressure)
  GetRelHumFromHumRatio = GetRelHumFromVapPres(TDryBulb, VapPres)
  Exit Function

ErrHandler:
  GetRelHumFromHumRatio = CVErr(xlErrNA)

End Function


Function GetHumRatioFromTDewPoint(ByVal TDewPoint As Variant, ByVal Pressure As Variant) As Variant
'
' Return humidity ratio given dew-point temperature and pressure.
'
' Args:
'        TDewPoint : Dew-point temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 13
'
  Dim VapPres As Variant

  On Error GoTo ErrHandler

  VapPres = GetSatVapPres(TDewPoint)
  GetHumRatioFromTDewPoint = GetHumRatioFromVapPres(VapPres, Pressure)
  Exit Function

ErrHandler:
  GetHumRatioFromTDewPoint = CVErr(xlErrNA)

End Function

Function GetTDewPointFromHumRatio(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
'
' Return dew-point temperature given dry-bulb temperature, humidity ratio, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        HumRatio : Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Dew-point temperature in °F [IP] or °C [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
  Dim VapPres As Variant

  On Error GoTo ErrHandler

  If HumRatio < 0 Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  VapPres = GetVapPresFromHumRatio(HumRatio, Pressure)
  GetTDewPointFromHumRatio = GetTDewPointFromVapPres(TDryBulb, VapPres)
  Exit Function

ErrHandler:
  GetTDewPointFromHumRatio = CVErr(xlErrNA)
End Function


'******************************************************************************************************
'       Conversions between humidity ratio and vapor pressure
'******************************************************************************************************

Function GetHumRatioFromVapPres(ByVal VapPres As Variant, ByVal Pressure As Variant) As Variant
'
' Return humidity ratio given water vapor pressure and atmospheric pressure.
'
' Args:
'        VapPres : Partial pressure of water vapor in moist air in Psi [IP] or Pa [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 20
'
  On Error GoTo ErrHandler

  If VapPres < 0 Then
    MyMsgBox ("Partial pressure of water vapor in moist air is negative")
    GoTo ErrHandler
  End If

  GetHumRatioFromVapPres = 0.621945 * VapPres / (Pressure - VapPres)
  Exit Function

ErrHandler:
  GetHumRatioFromVapPres = CVErr(xlErrNA)

End Function

Function GetVapPresFromHumRatio(ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
'
' Return vapor pressure given humidity ratio and pressure.
'
' Args:
'        HumRatio : Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Partial pressure of water vapor in moist air in Psi [IP] or Pa [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 20 solved for pw
'

  Dim VapPres As Variant

  On Error GoTo ErrHandler

  If HumRatio < 0 Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  VapPres = Pressure * HumRatio / (0.621945 + HumRatio)
  GetVapPresFromHumRatio = VapPres
  Exit Function

ErrHandler:
  GetVapPresFromHumRatio = CVErr(xlErrNA)

End Function


'******************************************************************************************************
'       Conversions between humidity ratio and specific humidity
'******************************************************************************************************

Function GetSpecificHumFromHumRatio(ByVal HumRatio As Variant) As Variant
'
' Return the specific humidity from humidity ratio (aka mixing ratio).
'
' Args:
'     HumRatio : Humidity ratio in lb_H₂O lb_Dry_Air⁻¹ [IP] or kg_H₂O kg_Dry_Air⁻¹ [SI]
'
' Returns:
'     Specific humidity in lb_H₂O lb_Air⁻¹ [IP] or kg_H₂O kg_Air⁻¹ [SI]
'
' Reference:
'     ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 9b
'
'
  Dim SpecificHum As Variant

  On Error GoTo ErrHandler

  If (HumRatio < 0) Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  SpecificHum = HumRatio / (1.0 + HumRatio)
  GetSpecificHumFromHumRatio = SpecificHum
  Exit Function

ErrHandler:
  GetSpecificHumFromHumRatio = CVErr(xlErrNA)

End Function

Function GetHumRatioFromSpecificHum(ByVal SpecificHum As Variant) As Variant
'
' Return the humidity ratio (aka mixing ratio) from specific humidity.
'
' Args:
'     SpecificHum : Specific Humidity in lb_H₂O lb_Air⁻¹ [IP] or kg_H₂O kg_Air⁻¹ [SI]
'
' Returns:
'     Humidity ratio in lb_H₂O lb_Dry_Air⁻¹ [IP] or kg_H₂O kg_Dry_Air⁻¹ [SI]
'
' Reference:
'     ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 9b (solved for humidity ratio)
'
'
  Dim HumRatio as Variant

  On Error GoTo ErrHandler

  If (SpecificHum < 0 Or SpecificHum >= 1) Then
    MyMsgBox ("Specific humidity is outside range [0, 1[")
    GoTo ErrHandler
  End If

    HumRatio = SpecificHum / (1.0 - SpecificHum)
    GetHumRatioFromSpecificHum = HumRatio
  Exit Function

ErrHandler:
  GetHumRatioFromSpecificHum = CVErr(xlErrNA)

End Function


'******************************************************************************************************
' Dry Air Calculations
'******************************************************************************************************

Function GetDryAirEnthalpy(ByVal TDryBulb As Variant) As Variant
'
' Return dry-air enthalpy given dry-bulb temperature.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'
' Returns:
'        Dry air enthalpy in Btu/lb [IP] or J/kg [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 28
'
  On Error GoTo ErrHandler

  If (isIP()) Then
    GetDryAirEnthalpy = 0.24 * TDryBulb
  Else
    GetDryAirEnthalpy = 1006 * TDryBulb
  End If
  Exit Function

ErrHandler:
  GetDryAirEnthalpy = CVErr(xlErrNA)

End Function

Function GetDryAirDensity(ByVal TDryBulb As Variant, ByVal Pressure As Variant) As Variant
'
' Return dry-air density given dry-bulb temperature and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Dry air density in lb/ft³ [IP] or kg/m³ [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
' Notes:
'        Eqn 14 for the perfect gas relationship for dry air.
'        Eqn 1 for the universal gas constant.
'        The factor 144 in IP is for the conversion of Psi = lb/in² to lb/ft².
'
  On Error GoTo ErrHandler

  If (isIP()) Then
    GetDryAirDensity = (144 * Pressure) / R_DA_IP / GetTRankineFromTFahrenheit(TDryBulb)
  Else
    GetDryAirDensity = Pressure / R_DA_SI / GetTKelvinFromTCelsius(TDryBulb)
  End If
  Exit Function

ErrHandler:
  GetDryAirDensity = CVErr(xlErrNA)

End Function

Function GetDryAirVolume(ByVal TDryBulb As Variant, ByVal Pressure As Variant) As Variant
'
' Return dry-air volume given dry-bulb temperature and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Dry air volume in ft³/lb [IP] or in m³/kg [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
' Notes:
'        Eqn 14 for the perfect gas relationship for dry air.
'        Eqn 1 for the universal gas constant.
'        The factor 144 in IP is for the conversion of Psi = lb/in² to lb/ft².
'
  On Error GoTo ErrHandler

  If (isIP()) Then
    GetDryAirVolume = GetTRankineFromTFahrenheit(TDryBulb) * R_DA_IP / (144 * Pressure)
  Else:
    GetDryAirVolume = GetTKelvinFromTCelsius(TDryBulb) * R_DA_SI / Pressure
  End If
  Exit Function

ErrHandler:
  GetDryAirVolume = CVErr(xlErrNA)

End Function

Function GetTDryBulbFromEnthalpyAndHumRatio(ByVal MoistAirEnthalpy As Variant, ByVal HumRatio As Variant) As Variant
'
' Return dry bulb temperature from enthalpy and humidity ratio.
'
'
' Args:
'     MoistAirEnthalpy : Moist air enthalpy in Btu lb⁻¹ [IP] or J kg⁻¹
'     HumRatio : Humidity ratio in lb_H₂O lb_Air⁻¹ [IP] or kg_H₂O kg_Air⁻¹ [SI]
'
' Returns:
'     Dry-bulb temperature in °F [IP] or °C [SI]
'
' Reference:
'     ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 30
'
' Notes:
'     Based on the `GetMoistAirEnthalpy` function, rearranged for temperature.
'

  On Error GoTo ErrHandler

  If HumRatio < 0 Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  If (isIP()) Then
    GetTDryBulbFromEnthalpyAndHumRatio = (MoistAirEnthalpy - 1061.0 * HumRatio) / (0.24 + 0.444 * HumRatio)
  Else:
    GetTDryBulbFromEnthalpyAndHumRatio = (MoistAirEnthalpy / 1000.0 - 2501.0 * HumRatio) / (1.006 + 1.86 * HumRatio)
  End If
  Exit Function

ErrHandler:
  GetTDryBulbFromEnthalpyAndHumRatio = CVErr(xlErrNA)

End Function

Function GetHumRatioFromEnthalpyAndTDryBulb(ByVal MoistAirEnthalpy As Variant, ByVal TDryBulb As Variant) As Variant
'
' Return humidity ratio from enthalpy and dry-bulb temperature.
'
'
' Args:
'     MoistAirEnthalpy : Moist air enthalpy in Btu lb⁻¹ [IP] or J kg⁻¹
'     TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'
' Returns:
'     Humidity ratio in lb_H₂O lb_Air⁻¹ [IP] or kg_H₂O kg_Air⁻¹ [SI]
'
' Reference:
'     ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 30
'
' Notes:
'     Based on the `GetMoistAirEnthalpy` function, rearranged for humidity ratio.
'

  On Error GoTo ErrHandler

  If (isIP()) Then
    GetHumRatioFromEnthalpyAndTDryBulb = (MoistAirEnthalpy - 0.24 * TDryBulb) / (1061.0 + 0.444 * TDryBulb)
  Else:
    GetHumRatioFromEnthalpyAndTDryBulb = (MoistAirEnthalpy / 1000.0 - 1.006 * TDryBulb) / (2501.0 + 1.86 * TDryBulb)
  End If
  Exit Function

ErrHandler:
  GetHumRatioFromEnthalpyAndTDryBulb = CVErr(xlErrNA)

End Function


'******************************************************************************************************
' Saturated Air Calculations
'******************************************************************************************************

Function GetSatVapPres(ByVal TDryBulb As Variant) As Variant
'
' Return saturation vapor pressure given dry-bulb temperature.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'
' Returns:
'        Vapor pressure of saturated air in Psi [IP] or Pa [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1  eqn 5 & 6
'
' Notes:
'       The SI formulae show a discontinuity at 0 C. In rare cases this discontinuity creates issues
'       in GetTDewPointFromVapPres. To avoid the problem, a small corrective term is added/subtracted
'       to the ASHRAE formulae to make the formulae continuous at 0 C. The effect on the results is
'       negligible (0.005%), well below the accuracy of the formulae
'
  Dim LnPws As Variant, T As Variant
  Const CORRECTIVE_TERM_SI = 4.851e-05 ' Small corrective term to make the function continuous at 0 C.

  On Error GoTo ErrHandler

  If (isIP()) Then
    If (TDryBulb < -148 Or TDryBulb > 392) Then
      MyMsgBox ("Dry bulb temperature is outside range [-148, 392] °F")
      GoTo ErrHandler
    End If

    T = GetTRankineFromTFahrenheit(TDryBulb)

    If (TDryBulb <= 32) Then
      LnPws = (-10214.165 / T - 4.8932428 - 0.0053765794 * T + 0.00000019202377 * T ^ 2 _
            + 3.5575832E-10 * T ^ 3 - 9.0344688E-14 * T ^ 4 + 4.1635019 * Log(T))
    Else
      LnPws = -10440.397 / T - 11.29465 - 0.027022355 * T + 0.00001289036 * T ^ 2 _
            - 2.4780681E-09 * T ^ 3 + 6.5459673 * Log(T)
    End If

  Else
    If (TDryBulb < -100 Or TDryBulb > 200) Then
      MyMsgBox ("Dry bulb temperature is outside range [-100, 200] °C")
      GoTo ErrHandler
    End If

    T = GetTKelvinFromTCelsius(TDryBulb)

    If (TDryBulb <= 0) Then
        LnPws = -5674.5359 / T + 6.3925247 - 0.009677843 * T + 0.00000062215701 * T ^ 2 _
              + 2.0747825E-09 * T ^ 3 - 9.484024E-13 * T ^ 4 + 4.1635019 * Log(T) + CORRECTIVE_TERM_SI
    Else
        LnPws = -5800.2206 / T + 1.3914993 - 0.048640239 * T + 0.000041764768 * T ^ 2 _
              - 0.000000014452093 * T ^ 3 + 6.5459673 * Log(T) - CORRECTIVE_TERM_SI
    End If
  End If

  GetSatVapPres = Exp(LnPws)
  Exit Function

ErrHandler:
  GetSatVapPres = CVErr(xlErrNA)

End Function

Function GetSatHumRatio(ByVal TDryBulb As Variant, ByVal Pressure As Variant) As Variant
'
' Return humidity ratio of saturated air given dry-bulb temperature and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Humidity ratio of saturated air in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 36, solved for W
'
  Dim SatVaporPres As Variant

  On Error GoTo ErrHandler

  SatVaporPres = GetSatVapPres(TDryBulb)
  GetSatHumRatio = 0.621945 * SatVaporPres / (Pressure - SatVaporPres)
  Exit Function

ErrHandler:
  GetSatHumRatio = CVErr(xlErrNA)

End Function

Function GetSatAirEnthalpy(ByVal TDryBulb As Variant, ByVal Pressure As Variant) As Variant
'
' Return saturated air enthalpy given dry-bulb temperature and pressure.
'
' Args:
'        TDryBulb: Dry-bulb temperature in °F [IP] or °C [SI]
'        Pressure: Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Saturated air enthalpy in Btu/lb [IP] or J/kg [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1
'
  On Error GoTo ErrHandler

  GetSatAirEnthalpy = GetMoistAirEnthalpy(TDryBulb, GetSatHumRatio(TDryBulb, Pressure))
  Exit Function

ErrHandler:
  GetSatAirEnthalpy = CVErr(xlErrNA)

End Function


'******************************************************************************************************
' Moist Air Calculations
'******************************************************************************************************


Function GetVaporPressureDeficit(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
'
' Return Vapor pressure deficit given dry-bulb temperature, humidity ratio, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        HumRatio : Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Vapor pressure deficit in Psi [IP] or Pa [SI]
'
' Reference:
'        Oke (1987) eqn 2.13a
'
  Dim RelHum As Variant

  On Error GoTo ErrHandler

  If HumRatio < 0 Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  RelHum = GetRelHumFromHumRatio(TDryBulb, HumRatio, Pressure)
  GetVaporPressureDeficit = GetSatVapPres(TDryBulb) * (1 - RelHum)
  Exit Function

ErrHandler:
  GetVaporPressureDeficit = CVErr(xlErrNA)

End Function

Function GetDegreeOfSaturation(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
'
' Return the degree of saturation (i.e humidity ratio of the air / humidity ratio of the air at saturation
' at the same temperature and pressure) given dry-bulb temperature, humidity ratio, and atmospheric pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        HumRatio : Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Degree of saturation in arbitrary unit
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2009) ch. 1 eqn 12
'
' Notes:
'        This definition is absent from the 2017 Handbook. Using 2009 version instead.

  On Error GoTo ErrHandler

  If HumRatio < 0 Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  GetDegreeOfSaturation = HumRatio / GetSatHumRatio(TDryBulb, Pressure)
  Exit Function

ErrHandler:
  GetDegreeOfSaturation = CVErr(xlErrNA)

End Function

Function GetMoistAirEnthalpy(ByVal TDryBulb As Variant, ByVal HumRatio As Variant) As Variant
'
' Return moist air enthalpy given dry-bulb temperature and humidity ratio.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        HumRatio : Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'
' Returns:
'        Moist air enthalpy in Btu/lb [IP] or J/kg
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 30
'
  On Error GoTo ErrHandler

  If (HumRatio < 0) Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  If (isIP()) Then
    GetMoistAirEnthalpy = 0.24 * TDryBulb + HumRatio * (1061 + 0.444 * TDryBulb)
  Else
    GetMoistAirEnthalpy = (1.006 * TDryBulb + HumRatio * (2501 + 1.86 * TDryBulb)) * 1000
  End If
  Exit Function

ErrHandler:
  GetMoistAirEnthalpy = CVErr(xlErrNA)

End Function

Function GetMoistAirVolume(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
'
' Return moist air specific volume given dry-bulb temperature, humidity ratio, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        HumRatio : Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Specific volume of moist air in ft³/lb of dry air [IP] or in m³/kg of dry air [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 26
'
' Notes:
'        In IP units, R_DA_IP / 144 equals 0.370486 which is the coefficient appearing in eqn 26
'        The factor 144 is for the conversion of Psi = lb/in² to lb/ft².
'
  On Error GoTo ErrHandler

  If (HumRatio < 0) Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  If (isIP()) Then
    GetMoistAirVolume = R_DA_IP * GetTRankineFromTFahrenheit(TDryBulb) * (1 + 1.607858 * HumRatio) / (144 * Pressure)
  Else
    GetMoistAirVolume = R_DA_SI * GetTKelvinFromTCelsius(TDryBulb) * (1 + 1.607858 * HumRatio) / Pressure
  End If
  Exit Function

ErrHandler:
  GetMoistAirVolume = CVErr(xlErrNA)

End Function

Function GetMoistAirDensity(ByVal TDryBulb As Variant, ByVal HumRatio As Variant, ByVal Pressure As Variant) As Variant
'
' Return moist air density given humidity ratio, dry bulb temperature, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        HumRatio : Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        MoistAirDensity: Moist air density in lb/ft³ [IP] or kg/m³ [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 11
'
  Dim MoistAirVolume As Variant

  On Error GoTo ErrHandler

  If (HumRatio < 0) Then
    MyMsgBox ("Humidity ratio is negative")
    GoTo ErrHandler
  End If

  MoistAirVolume = GetMoistAirVolume(TDryBulb, HumRatio, Pressure)
  GetMoistAirDensity = (1 + HumRatio) / MoistAirVolume
  Exit Function

ErrHandler:
  GetMoistAirDensity = CVErr(xlErrNA)

End Function


'******************************************************************************************************
' Standard atmosphere
'******************************************************************************************************

Function GetStandardAtmPressure(ByVal Altitude As Variant) As Variant
'
' Return standard atmosphere barometric pressure, given the elevation (altitude).
'
' Args:
'        Altitude: Altitude in ft [IP] or m [SI]
'
' Returns:
'        Standard atmosphere barometric pressure in Psi [IP] or Pa [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 3
'
  On Error GoTo ErrHandler

  If (isIP()) Then
    GetStandardAtmPressure = 14.696 * (1 - 0.0000068754 * Altitude) ^ 5.2559
  Else
    GetStandardAtmPressure = 101325 * (1 - 0.0000225577 * Altitude) ^ 5.2559
  End If
  Exit Function

ErrHandler:
  GetStandardAtmPressure = CVErr(xlErrNA)

End Function

Function GetStandardAtmTemperature(ByVal Altitude As Variant) As Variant
'
' Return standard atmosphere temperature, given the elevation (altitude).
'
' Args:
'        Altitude: Altitude in ft
'
' Returns:
'        Standard atmosphere dry-bulb temperature in °F [IP] or °C [SI]
'
' Reference:
'        ASHRAE Handbook - Fundamentals (2017) ch. 1 eqn 4
'
  On Error GoTo ErrHandler

  If (isIP()) Then
    GetStandardAtmTemperature = 59 - 0.0035662 * Altitude
  Else
    GetStandardAtmTemperature = 15 - 0.0065 * Altitude
  End If
  Exit Function

ErrHandler:
  GetStandardAtmTemperature = CVErr(xlErrNA)

End Function

Function GetSeaLevelPressure(ByVal StationPressure As Variant, ByVal Altitude As Variant, ByVal TDryBulb As Variant) As Variant
'
' Return sea level pressure given dry-bulb temperature, altitude above sea level and pressure.
'
' Args:
'        StationPressure : Observed station pressure in Psi [IP] or Pa [SI]
'        Altitude: Altitude in ft [IP] or m [SI]
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'
' Returns:
'        Sea level barometric pressure in Psi [IP] or Pa [SI]
'
' Reference:
'        Hess SL, Introduction to theoretical meteorology, Holt Rinehart and Winston, NY 1959,
'        ch. 6.5; Stull RB, Meteorology for scientists and engineers, 2nd edition,
'        Brooks/Cole 2000, ch. 1.
'
' Notes:
'        The standard procedure for the US is to use for TDryBulb the average
'        of the current station temperature and the station temperature from 12 hours ago.
'

  ' Calculate average temperature in column of air, assuming a lapse rate
  ' of 6.5 °C/km
  Dim TColumn As Variant
  Dim H As Variant

  On Error GoTo ErrHandler

  If (isIP()) Then
    ' Calculate average temperature in column of air, assuming a lapse rate
    ' of 3.6 °F/1000ft
    TColumn = TDryBulb + 0.0036 * Altitude / 2

    ' Determine the scale height
    H = 53.351 * GetTRankineFromTFahrenheit(TColumn)
  Else
    ' Calculate average temperature in column of air, assuming a lapse rate
    ' of 6.5 °C/km
    TColumn = TDryBulb + 0.0065 * Altitude / 2

    ' Determine the scale height
    H = 287.055 * GetTKelvinFromTCelsius(TColumn) / 9.807
  End If

  ' Calculate the sea level pressure
  GetSeaLevelPressure = StationPressure * Exp(Altitude / H)
  Exit Function

ErrHandler:
  GetSeaLevelPressure = CVErr(xlErrNA)

End Function

Function GetStationPressure(ByVal SeaLevelPressure As Variant, ByVal Altitude As Variant, ByVal TDryBulb As Variant) As Variant
'
' Args:
'        SeaLevelPressure : Sea level barometric pressure in Psi [IP] or Pa [SI]
'        Altitude: Altitude in ft [IP] or m [SI]
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'
' Returns:
'        Station pressure in Psi [IP] or Pa [SI]
'
' Reference:
'        See 'GetSeaLevelPressure'
'
' Notes:
'        This function is just the inverse of 'GetSeaLevelPressure'.
'
  On Error GoTo ErrHandler

  GetStationPressure = SeaLevelPressure / GetSeaLevelPressure(1, Altitude, TDryBulb)
  Exit Function

ErrHandler:
  GetStationPressure = CVErr(xlErrNA)

End Function

'******************************************************************************************************
' Functions to set all psychrometric values
'******************************************************************************************************

Sub CalcPsychrometricsFromTWetBulb(ByVal TDryBulb As Variant, ByVal TWetBulb As Variant, ByVal Pressure As Variant, _
    ByRef HumRatio As Variant, ByRef TDewPoint As Variant, ByRef RelHum As Variant, ByRef VapPres As Variant, _
    ByRef MoistAirEnthalpy As Variant, ByRef MoistAirVolume As Variant, ByRef DegreeOfSaturation As Variant)
'
' Utility function to calculate humidity ratio, dew-point temperature, relative humidity,
' vapour pressure, moist air enthalpy, moist air volume, and degree of saturation of air given
' dry-bulb temperature, wet-bulb temperature, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        TWetBulb : Wet-bulb temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Dew-point temperature in °F [IP] or °C [SI]
'        Relative humidity in range [0, 1]
'        Partial pressure of water vapor in moist air in Psi [IP] or Pa [SI]
'        Moist air enthalpy in Btu/lb [IP] or J/kg [SI]
'        Specific volume of moist air in ft³/lb [IP] or in m³/kg [SI]
'        Degree of saturation [unitless]
'
  HumRatio = GetHumRatioFromTWetBulb(TDryBulb, TWetBulb, Pressure)
  TDewPoint = GetTDewPointFromHumRatio(TDryBulb, HumRatio, Pressure)
  RelHum = GetRelHumFromHumRatio(TDryBulb, HumRatio, Pressure)
  VapPres = GetVapPresFromHumRatio(HumRatio, Pressure)
  MoistAirEnthalpy = GetMoistAirEnthalpy(TDryBulb, HumRatio)
  MoistAirVolume = GetMoistAirVolume(TDryBulb, HumRatio, Pressure)
  DegreeOfSaturation = GetDegreeOfSaturation(TDryBulb, HumRatio, Pressure)

End Sub

Sub CalcPsychrometricsFromTDewPoint(ByVal TDryBulb As Variant, ByVal TDewPoint As Variant, ByVal Pressure As Variant, _
    ByRef HumRatio As Variant, ByRef TWetBulb As Variant, ByRef RelHum As Variant, ByRef VapPres As Variant, _
    ByRef MoistAirEnthalpy As Variant, ByRef MoistAirVolume As Variant, ByRef DegreeOfSaturation As Variant)
'
' Utility function to calculate humidity ratio, wet-bulb temperature, relative humidity,
' vapour pressure, moist air enthalpy, moist air volume, and degree of saturation of air given
' dry-bulb temperature, dew-point temperature, and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        TDewPoint : Dew-point temperature in °F [IP] or °C [SI]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Wet-bulb temperature in °F [IP] or °C [SI]
'        Relative humidity in range [0, 1]
'        Partial pressure of water vapor in moist air in Psi [IP] or Pa [SI]
'        Moist air enthalpy in Btu/lb [IP] or J/kg [SI]
'        Specific volume of moist air in ft³/lb [IP] or in m³/kg [SI]
'        Degree of saturation [unitless]
'
  HumRatio = GetHumRatioFromTDewPoint(TDewPoint, Pressure)
  TWetBulb = GetTWetBulbFromHumRatio(TDryBulb, HumRatio, Pressure)
  RelHum = GetRelHumFromHumRatio(TDryBulb, HumRatio, Pressure)
  VapPres = GetVapPresFromHumRatio(HumRatio, Pressure)
  MoistAirEnthalpy = GetMoistAirEnthalpy(TDryBulb, HumRatio)
  MoistAirVolume = GetMoistAirVolume(TDryBulb, HumRatio, Pressure)
  DegreeOfSaturation = GetDegreeOfSaturation(TDryBulb, HumRatio, Pressure)

End Sub

Sub CalcPsychrometricsFromRelHum(ByVal TDryBulb As Variant, ByVal RelHum As Variant, ByVal Pressure As Variant, _
    ByRef HumRatio As Variant, ByRef TWetBulb As Variant, ByRef TDewPoint As Variant, ByRef VapPres As Variant, _
    ByRef MoistAirEnthalpy As Variant, ByRef MoistAirVolume As Variant, ByRef DegreeOfSaturation As Variant)
'
' Utility function to calculate humidity ratio, wet-bulb temperature, dew-point temperature,
' vapour pressure, moist air enthalpy, moist air volume, and degree of saturation of air given
' dry-bulb temperature, relative humidity and pressure.
'
' Args:
'        TDryBulb : Dry-bulb temperature in °F [IP] or °C [SI]
'        RelHum : Relative humidity in range [0, 1]
'        Pressure : Atmospheric pressure in Psi [IP] or Pa [SI]
'
' Returns:
'        Humidity ratio in lb_H2O/lb_Air [IP] or kg_H2O/kg_Air [SI]
'        Wet-bulb temperature in °F [IP] or °C [SI]
'        Dew-point temperature in °F [IP] or °C [SI].
'        Partial pressure of water vapor in moist air in Psi [IP] or Pa [SI]
'        Moist air enthalpy in Btu/lb [IP] or J/kg [SI]
'        Specific volume of moist air in ft³/lb [IP] or in m³/kg [SI]
'        Degree of saturation [unitless]
'
  HumRatio = GetHumRatioFromRelHum(TDryBulb, RelHum, Pressure)
  TWetBulb = GetTWetBulbFromHumRatio(TDryBulb, HumRatio, Pressure)
  TDewPoint = GetTDewPointFromHumRatio(TDryBulb, HumRatio, Pressure)
  VapPres = GetVapPresFromHumRatio(HumRatio, Pressure)
  MoistAirEnthalpy = GetMoistAirEnthalpy(TDryBulb, HumRatio)
  MoistAirVolume = GetMoistAirVolume(TDryBulb, HumRatio, Pressure)
  DegreeOfSaturation = GetDegreeOfSaturation(TDryBulb, HumRatio, Pressure)

End Sub
