//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                        Copyright 2017, Tim Hardy |
//|                                              
//+------------------------------------------------------------------+
#property copyright "Tim J Hardy"
#property strict

#include <stdlib.mqh>



bool SpreadTooHigh(double SpreadLimit = 10) 
   {
   RefreshRates();
   if (NormalizeDouble(Ask - Bid, Digits) > SpreadLimit) return(TRUE);
   return(FALSE);
   }
//-------------------------------
//-----------------------------------------------------------
void DrawVline (color Color, datetime time) 
 {//Typical Use: DrawVline(Yellow, Time[i]); //DrawVline(Yellow, Time[0]);
   static int cntr;
   static double PrevVlineTime;
   if (time == PrevVlineTime) //Still on same bar
      ObjectCreate( "UpLine"+cntr, OBJ_VLINE, 0, time, 0);
      ObjectSet("UpLine"+cntr, OBJPROP_COLOR, Color);
      ObjectSet("UpLine"+cntr, OBJPROP_BACK,true);
      cntr++;
      PrevVlineTime = time;//Store bar time of last drawn line
   
 }
 
 
int Crossed1(double line1,double line2) 
{

   static int CurrentDirection1=0;
   static int LastDirection1=0;
   static bool FirstTime1=true;

//----
   if(line1>line2)
      CurrentDirection1=1;  // line1 above line2
   if(line1<line2)
      CurrentDirection1=2;  // line1 below line2
//----
   if(FirstTime1==true) // Need to check if this is the first time the function is run
     {
      FirstTime1=false; // Change variable to false
      LastDirection1=CurrentDirection1; // Set new direction
      return (0);
     }

   if(CurrentDirection1!=LastDirection1 && FirstTime1==false) // If not the first time and there is a direction change
     {
      LastDirection1=CurrentDirection1; // Set new direction
      return(CurrentDirection1); // 1 for up, 2 for down
     }
   else
     {
      return(0);  // No direction change
     }

 }     
 
 
 double TopOfBar(int bar)
   {
   return (MathMax(Open[bar], Close[bar]));
   }
// returns the value of the bottom of the bar
double BottomOfBar(int bar)
   {
   return (MathMin(Open[bar], Close[bar]));
   }
// true if this is a down bar
bool DownBar(int bar)
  {
  return (Close[bar]<Open[bar]);
  }
// true if this is an up bar
bool UpBar(int bar)
  {
  return (Close[bar]>Open[bar]);
  }
// size of whole bar including the wicks
double HighLowSpread(int bar)
   {
   return (High[bar]-Low[bar]);
   }
// gives you the result of subtracting the lowest input value from the highest
double HighMinusLow(double value1, double value2)
   {
   double high = MathMax(value1, value2);
   double low = MathMin(value1, value2);
   return (high-low);
   }
   
   
   double UpperWickSize(int bar)
   {
   if (UpBar(bar))
      {
      return (High[bar]-Close[bar]);
      }
   if (DownBar(bar))
      {
      return (High[bar]-Open[bar]);
      }
   return (0);
   }
double LowerWickSize(int bar)
   {
   if (UpBar(bar))
      {
      return (Open[bar]-Low[bar]);
      }
   if (DownBar(bar))
      {
      return (Close[bar]-Low[bar]);
      }
   return (0);
   }
double BarBodySize(int bar)
  {
  if (UpBar(bar))
    {
    return (Close[bar]-Open[bar]);
    }
  if (DownBar(bar))
    {
    return (Open[bar]-Close[bar]);
    }
  return (0);
  }
  
  void drawHorizotalLine(string lineName = "hLine", double priceLevel = 0) {

   ObjectCreate(lineName, OBJ_HLINE, 0, Time[0], priceLevel); 

} 

double getProfitLinePrice() {

   double targetLine = ObjectGet("targetLine", OBJPROP_PRICE1) ;
   return targetLine;

} 

double getStopLinePrice() {

   double stopLine = ObjectGet("stopLine", OBJPROP_PRICE1) ;
   return stopLine;
}


// The example draws a line on selected chart every day at 8 o'clock
void drawVerticalLine(int barsBack) {
   
   string lineName = "Line"+MathRand();

   if (ObjectFind(lineName) != 0) {
      ObjectCreate(lineName,OBJ_VLINE,0,Time[barsBack],0);
      ObjectSet(lineName,OBJPROP_COLOR, clrRed);
      ObjectSet(lineName,OBJPROP_WIDTH,1);
      ObjectSet(lineName,OBJPROP_STYLE,STYLE_DOT);
   }
}