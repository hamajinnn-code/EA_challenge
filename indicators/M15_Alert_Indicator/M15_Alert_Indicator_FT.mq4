#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Aqua
#property indicator_color2 Pink
#property indicator_width1 2
#property indicator_width2 2

//+------------------------------------------------------------------+
//| M15_Alert_Indicator_FT                                           |
//| Forex Tester 6 friendly version                                  |
//|                                                                  |
//| This file is separate from the MT4 version. It keeps only the     |
//| EMA, H4 trend, signal, and arrow-buffer logic.                    |
//+------------------------------------------------------------------+

extern int    HistoricalBars  = 5000;
extern int    SlopeLookback   = 5;
extern double ArrowOffsetPips = 3.0;
extern color  BuyArrowColor   = Aqua;
extern color  SellArrowColor  = Pink;

double BuyArrowBuffer[];
double SellArrowBuffer[];

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int init()
{
   IndicatorShortName("M15_Alert_Indicator_FT");

   SetIndexBuffer(0, BuyArrowBuffer);
   SetIndexStyle(0, DRAW_ARROW, STYLE_SOLID, 2, BuyArrowColor);
   SetIndexArrow(0, 233);
   SetIndexEmptyValue(0, EMPTY_VALUE);
   SetIndexLabel(0, "BUY");

   SetIndexBuffer(1, SellArrowBuffer);
   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, SellArrowColor);
   SetIndexArrow(1, 234);
   SetIndexEmptyValue(1, EMPTY_VALUE);
   SetIndexLabel(1, "SELL");

   ArraySetAsSeries(BuyArrowBuffer, true);
   ArraySetAsSeries(SellArrowBuffer, true);

   return(0);
}

//+------------------------------------------------------------------+
//| Main calculation                                                 |
//+------------------------------------------------------------------+
int start()
{
   int ratesTotal = Bars;

   if(Period() != PERIOD_M15)
   {
      ClearArrowBuffers(ratesTotal);
      return(0);
   }

   UpdateArrowBuffers(ratesTotal);
   return(0);
}

//+------------------------------------------------------------------+
//| Pip value                                                        |
//+------------------------------------------------------------------+
double PipPoint()
{
   if(Digits == 3 || Digits == 5)
      return(Point * 10.0);

   return(Point);
}

//+------------------------------------------------------------------+
//| M15 EMA getter                                                   |
//+------------------------------------------------------------------+
double GetM15EMA(int period, int shift)
{
   return(iMA(NULL, PERIOD_M15, period, 0, MODE_EMA, PRICE_CLOSE, shift));
}

//+------------------------------------------------------------------+
//| Confirmed H4 shift for the M15 bar                               |
//+------------------------------------------------------------------+
int GetConfirmedH4ShiftForM15Shift(int m15Shift)
{
   datetime m15Time = iTime(NULL, PERIOD_M15, m15Shift);
   if(m15Time <= 0)
      return(-1);

   int h4Shift = iBarShift(NULL, PERIOD_H4, m15Time, false);
   if(h4Shift < 0)
      return(-1);

   return(h4Shift + 1);
}

//+------------------------------------------------------------------+
//| Data safety check                                                |
//+------------------------------------------------------------------+
bool HasEnoughBars(int shift)
{
   if(shift <= 0)
      return(false);

   int slopeBars = SlopeLookback;
   if(slopeBars < 1)
      slopeBars = 1;

   if(iBars(NULL, PERIOD_M15) <= shift + slopeBars + 200)
      return(false);

   int confirmedH4Shift = GetConfirmedH4ShiftForM15Shift(shift);
   if(confirmedH4Shift < 0)
      return(false);

   if(iBars(NULL, PERIOD_H4) <= confirmedH4Shift + 200)
      return(false);

   return(true);
}

//+------------------------------------------------------------------+
//| H4 trend: buy                                                    |
//+------------------------------------------------------------------+
bool IsH4BuyTrendForM15Shift(int m15Shift)
{
   int h4Shift = GetConfirmedH4ShiftForM15Shift(m15Shift);
   if(h4Shift < 0)
      return(false);

   double h4Close  = iClose(NULL, PERIOD_H4, h4Shift);
   double h4Ema200 = iMA(NULL, PERIOD_H4, 200, 0, MODE_EMA, PRICE_CLOSE, h4Shift);

   return(h4Close > h4Ema200);
}

//+------------------------------------------------------------------+
//| H4 trend: sell                                                   |
//+------------------------------------------------------------------+
bool IsH4SellTrendForM15Shift(int m15Shift)
{
   int h4Shift = GetConfirmedH4ShiftForM15Shift(m15Shift);
   if(h4Shift < 0)
      return(false);

   double h4Close  = iClose(NULL, PERIOD_H4, h4Shift);
   double h4Ema200 = iMA(NULL, PERIOD_H4, 200, 0, MODE_EMA, PRICE_CLOSE, h4Shift);

   return(h4Close < h4Ema200);
}

//+------------------------------------------------------------------+
//| M15 EMA alignment: buy                                           |
//+------------------------------------------------------------------+
bool IsM15BuyAlignment(int shift)
{
   double ema20  = GetM15EMA(20, shift);
   double ema75  = GetM15EMA(75, shift);
   double ema200 = GetM15EMA(200, shift);

   return(ema20 > ema75 && ema75 > ema200);
}

//+------------------------------------------------------------------+
//| M15 EMA alignment: sell                                          |
//+------------------------------------------------------------------+
bool IsM15SellAlignment(int shift)
{
   double ema20  = GetM15EMA(20, shift);
   double ema75  = GetM15EMA(75, shift);
   double ema200 = GetM15EMA(200, shift);

   return(ema20 < ema75 && ema75 < ema200);
}

//+------------------------------------------------------------------+
//| M15 EMA slope: buy                                               |
//+------------------------------------------------------------------+
bool IsM15BuySlopeUp(int shift)
{
   int lookback = SlopeLookback;
   if(lookback < 1)
      lookback = 1;

   double ema20Now  = GetM15EMA(20, shift);
   double ema75Now  = GetM15EMA(75, shift);
   double ema20Past = GetM15EMA(20, shift + lookback);
   double ema75Past = GetM15EMA(75, shift + lookback);

   return(ema20Now > ema20Past && ema75Now > ema75Past);
}

//+------------------------------------------------------------------+
//| M15 EMA slope: sell                                              |
//+------------------------------------------------------------------+
bool IsM15SellSlopeDown(int shift)
{
   int lookback = SlopeLookback;
   if(lookback < 1)
      lookback = 1;

   double ema20Now  = GetM15EMA(20, shift);
   double ema75Now  = GetM15EMA(75, shift);
   double ema20Past = GetM15EMA(20, shift + lookback);
   double ema75Past = GetM15EMA(75, shift + lookback);

   return(ema20Now < ema20Past && ema75Now < ema75Past);
}

//+------------------------------------------------------------------+
//| Candle direction                                                 |
//+------------------------------------------------------------------+
bool IsBullishCandle(int shift)
{
   return(Close[shift] > Open[shift]);
}

bool IsBearishCandle(int shift)
{
   return(Close[shift] < Open[shift]);
}

//+------------------------------------------------------------------+
//| Touch logic                                                      |
//+------------------------------------------------------------------+
bool IsBuyTouch20Or75EMA(int shift)
{
   double ema20 = GetM15EMA(20, shift);
   double ema75 = GetM15EMA(75, shift);

   bool touch20 = (Low[shift] <= ema20 && Close[shift] >= ema20);
   bool touch75 = (Low[shift] <= ema75 && Close[shift] >= ema75);

   return(touch20 || touch75);
}

bool IsSellTouch20Or75EMA(int shift)
{
   double ema20 = GetM15EMA(20, shift);
   double ema75 = GetM15EMA(75, shift);

   bool touch20 = (High[shift] >= ema20 && Close[shift] <= ema20);
   bool touch75 = (High[shift] >= ema75 && Close[shift] <= ema75);

   return(touch20 || touch75);
}

//+------------------------------------------------------------------+
//| Pullback reset logic                                             |
//+------------------------------------------------------------------+
bool IsBuyPullbackReset(int shift)
{
   double ema20 = GetM15EMA(20, shift);
   return(Close[shift] > ema20 && Low[shift] > ema20);
}

bool IsSellPullbackReset(int shift)
{
   double ema20 = GetM15EMA(20, shift);
   return(Close[shift] < ema20 && High[shift] < ema20);
}

//+------------------------------------------------------------------+
//| Signal logic                                                     |
//+------------------------------------------------------------------+
bool IsBuySignal(int shift)
{
   if(shift <= 0)
      return(false);
   if(!HasEnoughBars(shift))
      return(false);
   if(!IsH4BuyTrendForM15Shift(shift))
      return(false);
   if(!IsM15BuyAlignment(shift))
      return(false);
   if(!IsM15BuySlopeUp(shift))
      return(false);
   if(!IsBuyTouch20Or75EMA(shift))
      return(false);
   if(!IsBullishCandle(shift))
      return(false);

   return(true);
}

bool IsSellSignal(int shift)
{
   if(shift <= 0)
      return(false);
   if(!HasEnoughBars(shift))
      return(false);
   if(!IsH4SellTrendForM15Shift(shift))
      return(false);
   if(!IsM15SellAlignment(shift))
      return(false);
   if(!IsM15SellSlopeDown(shift))
      return(false);
   if(!IsSellTouch20Or75EMA(shift))
      return(false);
   if(!IsBearishCandle(shift))
      return(false);

   return(true);
}

//+------------------------------------------------------------------+
//| Scan range                                                       |
//+------------------------------------------------------------------+
int GetScanBars(int rates_total)
{
   int scanBars = HistoricalBars;
   if(scanBars < 1)
      scanBars = 1;
   if(scanBars > 20000)
      scanBars = 20000;
   if(scanBars > Bars - 300)
      scanBars = Bars - 300;
   if(scanBars > rates_total - 1)
      scanBars = rates_total - 1;
   if(scanBars < 1)
      scanBars = 1;

   return(scanBars);
}

//+------------------------------------------------------------------+
//| Buffer clearing                                                  |
//+------------------------------------------------------------------+
void ClearArrowBuffers(int rates_total)
{
   int limit = rates_total - 1;
   if(limit > Bars - 1)
      limit = Bars - 1;

   for(int i = 0; i <= limit; i++)
   {
      BuyArrowBuffer[i] = EMPTY_VALUE;
      SellArrowBuffer[i] = EMPTY_VALUE;
   }
}

//+------------------------------------------------------------------+
//| Arrow buffer update                                              |
//+------------------------------------------------------------------+
void UpdateArrowBuffers(int rates_total)
{
   int scanBars = GetScanBars(rates_total);
   int clearLimit = scanBars;
   if(clearLimit > Bars - 1)
      clearLimit = Bars - 1;

   for(int clearShift = 0; clearShift <= clearLimit; clearShift++)
   {
      BuyArrowBuffer[clearShift] = EMPTY_VALUE;
      SellArrowBuffer[clearShift] = EMPTY_VALUE;
   }

   bool buySignalAlreadyShown = false;
   bool sellSignalAlreadyShown = false;
   double arrowOffset = ArrowOffsetPips * PipPoint();

   for(int shift = scanBars; shift >= 1; shift--)
   {
      bool buyAlignment = IsM15BuyAlignment(shift);
      bool sellAlignment = IsM15SellAlignment(shift);

      if(!buyAlignment || !IsM15BuySlopeUp(shift) || IsBuyPullbackReset(shift))
         buySignalAlreadyShown = false;

      if(!sellAlignment || !IsM15SellSlopeDown(shift) || IsSellPullbackReset(shift))
         sellSignalAlreadyShown = false;

      if(buyAlignment && !buySignalAlreadyShown && IsBuySignal(shift))
      {
         BuyArrowBuffer[shift] = Low[shift] - arrowOffset;
         SellArrowBuffer[shift] = EMPTY_VALUE;
         buySignalAlreadyShown = true;
         continue;
      }

      if(sellAlignment && !sellSignalAlreadyShown && IsSellSignal(shift))
      {
         SellArrowBuffer[shift] = High[shift] + arrowOffset;
         BuyArrowBuffer[shift] = EMPTY_VALUE;
         sellSignalAlreadyShown = true;
      }
   }

   BuyArrowBuffer[0] = EMPTY_VALUE;
   SellArrowBuffer[0] = EMPTY_VALUE;
}
