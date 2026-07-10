#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1 DodgerBlue
#property indicator_color2 Orange
#property indicator_color3 Silver
#property indicator_color4 Aqua
#property indicator_color5 Pink
#property indicator_width1 1
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 2
#property indicator_width5 2

input int HistoricalBars = 5000;

double Ema20Buffer[];
double Ema75Buffer[];
double Ema200Buffer[];
double BuyArrowBuffer[];
double SellArrowBuffer[];

int OnInit()
{
   IndicatorShortName("M15_Alert_Indicator_FT_Display_Check");

   SetIndexBuffer(0, Ema20Buffer);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, DodgerBlue);
   SetIndexLabel(0, "EMA 20");

   SetIndexBuffer(1, Ema75Buffer);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, Orange);
   SetIndexLabel(1, "EMA 75");

   SetIndexBuffer(2, Ema200Buffer);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, Silver);
   SetIndexLabel(2, "EMA 200");

   SetIndexBuffer(3, BuyArrowBuffer);
   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, Aqua);
   SetIndexArrow(3, 233);
   SetIndexEmptyValue(3, EMPTY_VALUE);
   SetIndexLabel(3, "BUY");

   SetIndexBuffer(4, SellArrowBuffer);
   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 2, Pink);
   SetIndexArrow(4, 234);
   SetIndexEmptyValue(4, EMPTY_VALUE);
   SetIndexLabel(4, "SELL");

   ArraySetAsSeries(Ema20Buffer, true);
   ArraySetAsSeries(Ema75Buffer, true);
   ArraySetAsSeries(Ema200Buffer, true);
   ArraySetAsSeries(BuyArrowBuffer, true);
   ArraySetAsSeries(SellArrowBuffer, true);

   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int limit = MathMin(rates_total - 1, HistoricalBars);

   for(int i = limit; i >= 1; i--)
   {
      Ema20Buffer[i] = iMA(NULL, 0, 20, 0, MODE_EMA, PRICE_CLOSE, i);
      Ema75Buffer[i] = iMA(NULL, 0, 75, 0, MODE_EMA, PRICE_CLOSE, i);
      Ema200Buffer[i] = iMA(NULL, 0, 200, 0, MODE_EMA, PRICE_CLOSE, i);

      BuyArrowBuffer[i] = EMPTY_VALUE;
      SellArrowBuffer[i] = EMPTY_VALUE;

      if(Ema20Buffer[i] > Ema75Buffer[i] &&
         Ema75Buffer[i] > Ema200Buffer[i] &&
         Low[i] <= Ema20Buffer[i] &&
         Close[i] > Open[i])
      {
         BuyArrowBuffer[i] = Low[i] - 10 * Point;
      }
      else if(Ema20Buffer[i] < Ema75Buffer[i] &&
              Ema75Buffer[i] < Ema200Buffer[i] &&
              High[i] >= Ema20Buffer[i] &&
              Close[i] < Open[i])
      {
         SellArrowBuffer[i] = High[i] + 10 * Point;
      }
   }

   Ema20Buffer[0] = iMA(NULL, 0, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
   Ema75Buffer[0] = iMA(NULL, 0, 75, 0, MODE_EMA, PRICE_CLOSE, 0);
   Ema200Buffer[0] = iMA(NULL, 0, 200, 0, MODE_EMA, PRICE_CLOSE, 0);
   BuyArrowBuffer[0] = EMPTY_VALUE;
   SellArrowBuffer[0] = EMPTY_VALUE;

   return(rates_total);
}
