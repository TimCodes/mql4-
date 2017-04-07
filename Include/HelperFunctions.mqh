//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                        Copyright 2017, Tim Hardy |
//|                                              
//+------------------------------------------------------------------+
#property copyright "Tim J Hardy"
#property strict

#include <stdlib.mqh>

class HelperFunctions
{
};

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