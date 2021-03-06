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
      Setup:
            Close greater than 100-day moving average
            Close less than the 5-day moving average
            3 lower lows. (Not lower closes, I made this mistake the first time I wrote the code)

      BUY: set a limit buy order for the next day if price falls another .5 times 10-day average true range.
          
           
      SELL: Sell on the next open
                
    
    EXIT RUlLES:  Close is greater than the previous day’s close
    
*/



//+------------------------------------------------------------------+
//| Includes and object initialization                               |
//+------------------------------------------------------------------+

#include <Utils\TradeManager.mqh>
TradeManager Trade;

#include <Utils\OrderWrapper.mqh>
OrderCount Count;


#include <Utils\HelperFunctions.mqh>


#include <Timer.mqh>
CTimer Timer;
CNewBar NewBar;

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
input int StopLoss = 30;
input int TakeProfit = 90;

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

extern int smaPeriodShort = 5;
extern int smaPeriodLong = 100;
extern int ATRPeriod=10;


//+------------------------------------------------------------------+
//| Global variable and indicators                                   |
//+------------------------------------------------------------------+

int gBuyTicket, gSellTicket;
double low1, low2, low3, low4;

double close1;
double lowPriceThreshold;

double sma_short, sma_long;
double myATR;
bool isSetup = False;
string setupType = NULL;
bool newBar = true;


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
     RefreshRates();
     
        double  open ;
   // Check timer
     newBar = NewBar.CheckNewBar(_Symbol,_Period);
    
      
     if(newBar == True){
          
      open =  Open[0];
          
          
          
          low1  = iLow(NULL, 0, 1);
          low2  = iLow(NULL, 0, 2);
          low3  = iLow(NULL, 0, 3);
          low4  = iLow(NULL, 0, 4);
       
             
          close1 = iClose(NULL, 0, 1);
            
          sma_short = iMA(NULL, 0, smaPeriodShort, 0, 0, 0, 1);
          sma_long = iMA(NULL, 0, smaPeriodLong, 0, 0, 0, 1);
          myATR=iATR(NULL,Period(),ATRPeriod,1);
          
          lowPriceThreshold = low1 - (myATR * .5); 
         
          
          if( low1 < low2 && low2 < low3 && low3 < low4){
            if(close1 > sma_long && close1 < sma_short ){
              isSetup = TRUE;
              
            }
         }
         
         if(isSetup == TRUE){
              /// maybe do some defeinsive coding here make sure open is not null or zero
              // alo paly with max lots open at one time
              // start using a better sizing algo, kelly?
             if( open <=  lowPriceThreshold  && Count.Buy() < 2){
                     
                    Print(" low open is lower tha threshsold open buy");
                    Print(open); 
                   gBuyTicket = Trade.OpenInstantBuyOrder(_Symbol, FixedLotSize, StopLoss, TakeProfit); ;
                 //  isSetup = false;
         }
         
        
     }
      /// maybe only set this on new bar
      //  sorted array here
      // func isDec(arr) arr => arr.isTrue( arr[1] < arr[2] )
     
      /// what to do here after set up has happend 
      // maybe wait for another bar and see if its lower 
      // the atr rule
      
      // or use bid and ask prices to see if the fall below on current bar
      
      
      // Open buy order.
      
   
         
      }
      
     
  
   // Break even stop
   
}