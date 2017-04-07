//+------------------------------------------------------------------+
//|                                      Expert Advisor Template.mq4 |
//|                                                Tim Hardy |
//|                                |
//+------------------------------------------------------------------+

#property copyright     "Tim Hardy"

#property strict


//+------------------------------------------------------------------+
//| Includes and object initialization                               |
//+------------------------------------------------------------------+


/*
   ENTRY RULES: 
      BUY: ....
          
           
      SELL: 
                
    
    EXIT RUlLES:  ....
    
*/



//+------------------------------------------------------------------+
//| Includes and object initialization                               |
//+------------------------------------------------------------------+

#include <Utils\TradeManager.mqh>
TradeManager Trade;

#include <Utils\OrderWrapper.mqh>
OrderCount Count;


#include <Utils\HelperFunctions.mqh>


//+------------------------------------------------------------------+
//| Input variables                                       |
//+------------------------------------------------------------------+

sinput string TradeSettings;    	// Trade Settings
input int MagicNumber = 101;
input int Slippage = 10;
input bool TradeOnBarOpen = true;

sinput string MoneyManagement;  	// Money Management
input bool UseMoneyManagement = true;
input double RiskPercent = 2;
input double FixedLotSize = 0.1;

sinput string Stops;				// Stop Loss & Take Profit
input int StopLoss = 0;
input int TakeProfit = 0;

sinput string TrailingStopSettings;	// Trailing Stop
input bool UseTrailingStop = true;
input int TrailingStop = 0;
input int MinProfit = 0;
input int Step = 10;

sinput string BreakEvenSettings	;	// Break Even Stop
input bool UseBreakEvenStop = false;
input int MinimumProfit = 0;
input int LockProfit = 0;

sinput string TimerSetting;		// Timer
input bool UseTimer = false;
input int StartHour = 0;
input int StartMinute = 0;
input int EndHour = 0;
input int EndMinute = 0;
input bool UseLocalTime = false;


//+------------------------------------------------------------------+
//| Global variable and indicators                                   |
//+------------------------------------------------------------------+

int gBuyTicket, gSellTicket;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
   // Set magic number
   Trade.SetMagicNumber(MagicNumber);
   Trade.SetSlippage(Slippage);
   
   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
   // Check timer
   
  
      // Open buy order
      if( TRUE )
      {
         gBuyTicket = Trade.OpenInstantBuyOrder(_Symbol, FixedLotSize, StopLoss, TakeProfit); ;
        
      }
      
      // Open sell order
      else if( TRUE  )
      {
         gSellTicket = Trade.OpenInstantSellOrder(_Symbol, FixedLotSize, StopLoss, TakeProfit); 
         
      }
  
   // Break even stop
   
}