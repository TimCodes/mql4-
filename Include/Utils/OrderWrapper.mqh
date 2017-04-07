//+------------------------------------------------------------------+
//|                                                 OrderWrapper.mqh |
//|                                        Copyright 2017, Tim Hardy |
//|                                              
//+------------------------------------------------------------------+
#property copyright "Tim J Hardy"
#property strict

#include <stdlib.mqh>

#define MAX_RETRIES 3		// Max retries on error
#define RETRY_DELAY 3000	// Retry delay in ms



class OrderCount
{
   private:  
      enum COUNT_ORDER_TYPE
      {
         COUNT_BUY,
         COUNT_SELL,
         COUNT_BUY_STOP,
         COUNT_SELL_STOP,
         COUNT_BUY_LIMIT,
         COUNT_SELL_LIMIT,
         COUNT_MARKET,
         COUNT_PENDING,
         COUNT_ALL
      };
      
      int CountOrders(COUNT_ORDER_TYPE pType);
 
      
   public:
      int Buy();
      int Sell();
      int BuyStop();
      int SellStop();
      int BuyLimit();
      int SellLimit();
      int TotalMarket();
      int TotalPending();
      int TotalOrders();
};


int OrderCount::CountOrders(COUNT_ORDER_TYPE pType)
{
   // Order counts
   int buy = 0, sell = 0, buyStop = 0, sellStop = 0, 
      buyLimit = 0, sellLimit = 0, totalOrders = 0;
   
   // Loop through open order pool from oldest to newest
   for(int order = 0; order <= OrdersTotal() - 1; order++)
   {
      // Select order
      bool result = OrderSelect(order,SELECT_BY_POS);
      
      int orderType = OrderType();
      int orderMagicNumber = OrderMagicNumber();
      
      // Add to order count if magic number matches
    //  if(orderMagicNumber == CTrade::GetMagicNumber())
    //  {
         switch(orderType)
         {
            case OP_BUY:
               buy++;
               break;
               
            case OP_SELL:
               sell++;
               break;
               
            case OP_BUYLIMIT:
               buyLimit++;
               break;
               
            case OP_SELLLIMIT:
               sellLimit++;
               break;   
               
            case OP_BUYSTOP:
               buyStop++;
               break;
               
            case OP_SELLSTOP:
               sellStop++;
               break;          
         }
         
         totalOrders++;
     // }
   }
   
   // Return order count based on pType
   int returnTotal = 0;
   switch(pType)
   {
      case COUNT_BUY:
         returnTotal = buy;
         break;
         
      case COUNT_SELL:
         returnTotal = sell;
         break;
         
      case COUNT_BUY_LIMIT:
         returnTotal = buyLimit;
         break;
         
      case COUNT_SELL_LIMIT:
         returnTotal = sellLimit;
         break;
         
      case COUNT_BUY_STOP:
         returnTotal = buyStop;
         break;
         
      case COUNT_SELL_STOP:
         returnTotal = sellStop;
         break;
         
      case COUNT_MARKET:
         returnTotal = buy + sell;
         break;
         
      case COUNT_PENDING:
         returnTotal = buyLimit + sellLimit + buyStop + sellStop;
         break;   
         
      case COUNT_ALL:
         returnTotal = totalOrders; 
         break;        
   }
   
   return(returnTotal);
}


int OrderCount::Buy(void)
{
   int total = CountOrders(COUNT_BUY);
   return(total);
}

int OrderCount::Sell(void)
{
   int total = CountOrders(COUNT_SELL);
   return(total);
}

int OrderCount::BuyLimit(void)
{
   int total = CountOrders(COUNT_BUY_LIMIT);
   return(total);
}

int OrderCount::SellLimit(void)
{
   int total = CountOrders(COUNT_SELL_LIMIT);
   return(total);
}

int OrderCount::BuyStop(void)
{
   int total = CountOrders(COUNT_BUY_STOP);
   return(total);
}

int OrderCount::SellStop(void)
{
   int total = CountOrders(COUNT_SELL_STOP);
   return(total);
}

int OrderCount::TotalMarket(void)
{
   int total = CountOrders(COUNT_MARKET);
   return(total);
}

int OrderCount::TotalPending(void)
{
   int total = CountOrders(COUNT_PENDING);
   return(total);
}

int OrderCount::TotalOrders(void)
{
   int total = CountOrders(COUNT_ALL);
   return(total);
}