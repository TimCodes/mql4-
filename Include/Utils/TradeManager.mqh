//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                        Copyright 2017, Tim Hardy |
//|                                              
//+------------------------------------------------------------------+
#property copyright "Tim J Hardy"
#property strict

#include <stdlib.mqh>

#define MAX_RETRIES 3		// Max retries on error
#define RETRY_DELAY 3000	// Retry delay in ms



class TradeManager
{
   private:
         static int _magicNumber;
         static int _slippage;
         
         enum CLOSE_MARKET_TYPE
         {
            CLOSE_BUY,
            CLOSE_SELL,
            CLOSE_ALL_MARKET
         };
         
         enum CLOSE_PENDING_TYPE
         {
            CLOSE_BUY_LIMIT,
            CLOSE_SELL_LIMIT,
            CLOSE_BUY_STOP,
            CLOSE_SELL_STOP,
            CLOSE_ALL_PENDING
         };
         
         int OpenMarketOrder(string pSymbol, int pType, double pVolume, string pComment, color pArrow);
         int OpenInstantOrder(string pSymbol, int pType, double pVolume, int stopLoss, int takeProfit,  string pComment, color pArrow);
         int OpenPendingOrder(string pSymbol, int pType, double pVolume, double pPrice, double pStop, double pProfit, string pComment, datetime pExpiration, color pArrow);
         
         bool CloseMultipleOrders(CLOSE_MARKET_TYPE pCloseType);
         bool DeleteMultipleOrders(CLOSE_PENDING_TYPE pDeleteType);
   
      
      public:
         int OpenBuyOrder(string pSymbol, double pVolume, string pComment = "Buy order", color pArrow = clrGreen);
         int OpenSellOrder(string pSymbol, double pVolume, string pComment = "Sell order", color pArrow = clrRed);
         
         int OpenInstantBuyOrder(string pSymbol, double pVolume, int stopLoss, int takeProfit, string pComment = "Open Instant Buy Order", color pArrow = clrGreen);
         int OpenInstantSellOrder(string pSymbol, double pVolume, int stopLoss, int takeProfit, string pComment = "Open Instnat Sell order", color pArrow = clrRed);
         
         int OpenBuyStopOrder(string pSymbol, double pVolume, double pPrice, double pStop, double pProfit, string pComment = "Buy stop order", datetime pExpiration = 0, color pArrow = clrBlue);
         int OpenSellStopOrder(string pSymbol, double pVolume, double pPrice, double pStop, double pProfit, string pComment = "Sell stop order", datetime pExpiration = 0, color pArrow = clrIndigo);
         int OpenBuyLimitOrder(string pSymbol, double pVolume, double pPrice, double pStop, double pProfit, string pComment = "Buy limit order", datetime pExpiration = 0, color pArrow = clrCornflowerBlue);
         int OpenSellLimitOrder(string pSymbol, double pVolume, double pPrice, double pStop, double pProfit, string pComment = "Sell limit order", datetime pExpiration = 0, color pArrow = clrMediumSlateBlue);
         
         bool CloseMarketOrder(int pTicket, double pVolume = 0, color pArrow = clrRed);
         bool CloseAllBuyOrders();
         bool CloseAllSellOrders();
         bool CloseAllMarketOrders();
         
         bool DeletePendingOrder(int pTicket, color pArrow = clrRed);
         bool DeleteAllBuyStopOrders();
         bool DeleteAllSellStopOrders();
         bool DeleteAllBuyLimitOrders();
         bool DeleteAllSellLimitOrders();
         bool DeleteAllPendingOrders();
         
         static void SetMagicNumber(int pMagic);
         static int GetMagicNumber();
         
         static void SetSlippage(int pSlippage);     
};


int TradeManager::_magicNumber = 0;
int TradeManager::_slippage = 10;


int TradeManager::OpenMarketOrder(string pSymbol, int pType, double pVolume, string pComment, color pArrow)
{
	int retryCount = 0;
	int ticket = 0;
	int errorCode = 0;
	
	double orderPrice = 0;
	
	string orderType;
	string errDesc;
	
	// Order retry loop
	while(retryCount <= MAX_RETRIES) 
	{
		while(IsTradeContextBusy()) Sleep(10);
		RefreshRates();
		// Get current bid/ask price
		if(pType == OP_BUY) orderPrice = MarketInfo(pSymbol,MODE_ASK);
		else if(pType == OP_SELL) orderPrice = MarketInfo(pSymbol,MODE_BID);

		// Place market order
		ticket = OrderSend(pSymbol,pType,pVolume,orderPrice,_slippage,0,0,pComment,_magicNumber,0,pArrow);
	   
		// Error handling
		if(ticket == -1)
		{
			errorCode = GetLastError();
			errDesc = ErrorDescription(errorCode);
			bool checkError = RetryOnError(errorCode);
			orderType = OrderTypeToString(pType);
			
			// Unrecoverable error
			if(checkError == false)
			{
				Alert("Open ",orderType," order: Error ",errorCode," - ",errDesc);
				Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",orderPrice);
				break;
			}
			
			// Retry on error
			else
			{
				Print("Server error detected, retrying...");
				Sleep(RETRY_DELAY);
				retryCount++;
			}
		}
		
		// Order successful
		else
		{
		   orderType = OrderTypeToString(pType);
		   Comment(orderType," order #",ticket," opened on ",pSymbol);
		   Print(orderType," order #",ticket," opened on ",pSymbol);
		   break;
		} 
   }
   
   // Failed after retry
	if(retryCount > MAX_RETRIES)
	{
		Alert("Open ",orderType," order: Max retries exceeded. Error ",errorCode," - ",errDesc);
		Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",orderPrice);
	}
   
   return(ticket);
}  


int TradeManager::OpenBuyOrder(string pSymbol,double pVolume,string pComment="Buy order",color pArrow=32768)
{
   int ticket = OpenMarketOrder(pSymbol, OP_BUY, pVolume, pComment, pArrow);
   return(ticket);
}


int TradeManager::OpenSellOrder(string pSymbol,double pVolume,string pComment="Sell order",color pArrow=255)
{
   int ticket = OpenMarketOrder(pSymbol, OP_SELL, pVolume, pComment, pArrow);
   return(ticket);
}


//+------------------------------------------------------------------+
//| Instant order functions                                          |
//+------------------------------------------------------------------+

int TradeManager::OpenInstantOrder(string pSymbol, int pType, double pVolume, int stopLoss, int takeProfit,  string pComment, color pArrow)
{
	int retryCount = 0;
	int ticket = 0;
	int errorCode = 0;
	
	double orderPrice = 0;
	double stoploss  =  0;
	double takeprofit = 0;
	
	string orderType;
	string errDesc;
	
	datetime expiration=0;
	
	// Order retry loop
	while(retryCount <= MAX_RETRIES) 
	{
		while(IsTradeContextBusy()) Sleep(10);
		RefreshRates();
		// Get current bid/ask price
		if(pType == OP_BUY){
		 orderPrice = MarketInfo(pSymbol,MODE_ASK);
		 takeprofit = BuyTakeProfit( pSymbol, takeProfit, orderPrice);
		 stoploss   = BuyStopLoss( pSymbol, stopLoss, orderPrice);
		 Print("****** volume size  buy ******");
		 Print(pVolume);
		 
		}else if(pType == OP_SELL){
		  orderPrice = MarketInfo(pSymbol,MODE_BID);
		  takeprofit = SellTakeProfit( pSymbol, takeProfit, orderPrice);
		  stoploss   = SellStopLoss( pSymbol, stopLoss, orderPrice);
		  
		}   

		// Place Instant order
		
		ticket = OrderSend(pSymbol,pType,pVolume,orderPrice,_slippage,stoploss,takeprofit,pComment,_magicNumber,expiration,pArrow);
	   
		// Error handling
		if(ticket == -1)
		{
			errorCode = GetLastError();
			errDesc = ErrorDescription(errorCode);
			bool checkError = RetryOnError(errorCode);
			orderType = OrderTypeToString(pType);
			
			// Unrecoverable error
			if(checkError == false)
			{
				Alert("Open ",orderType," order: Error ",errorCode," - ",errDesc);
				Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",orderPrice);
				break;
			}
			
			// Retry on error
			else
			{
				Print("Server error detected, retrying...");
				Sleep(RETRY_DELAY);
				retryCount++;
			}
		}
		
		// Order successful
		else
		{
		   orderType = OrderTypeToString(pType);
		   Comment(orderType," order #",ticket," opened on ",pSymbol);
		   Print(orderType," order #",ticket," opened on ",pSymbol);
		   break;
		} 
   }
   
   // Failed after retry
	if(retryCount > MAX_RETRIES)
	{
		Alert("Open ",orderType," order: Max retries exceeded. Error ",errorCode," - ",errDesc);
		Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",orderPrice);
	}
   
   return(ticket);
}  



 int TradeManager::OpenInstantBuyOrder(string pSymbol, double pVolume, int stopLoss, int takeProfit, string pComment = "Open Instant Buy Order", color pArrow = clrGreen)
 {  
   int ticket = OpenInstantOrder(pSymbol, OP_BUY, pVolume, stopLoss, takeProfit, pComment, pArrow);
   return(ticket);
 }
 
  int TradeManager::OpenInstantSellOrder(string pSymbol, double pVolume, int stopLoss, int takeProfit, string pComment = "Open Instnat Sell order", color pArrow = clrRed)
 {  
   int ticket = OpenInstantOrder(pSymbol, OP_SELL, pVolume, stopLoss, takeProfit, pComment, pArrow);
   return(ticket);
 }


//+------------------------------------------------------------------+
//| Pending order functions                                          |
//+------------------------------------------------------------------+

int TradeManager::OpenPendingOrder(string pSymbol,int pType,double pVolume,double pPrice,double pStop,double pProfit,string pComment,datetime pExpiration,color pArrow)
{
   int retryCount = 0;
	int ticket = 0;
	int errorCode = 0;

	string orderType;
	string errDesc;
	
	// Order retry loop
	while(retryCount <= MAX_RETRIES)
	{
		while(IsTradeContextBusy()) Sleep(10);
		ticket = OrderSend(pSymbol, pType, pVolume, pPrice, _slippage, pStop, pProfit, pComment, _magicNumber, pExpiration, pArrow);
		
		// Error handling
		if(ticket == -1)
		{
			errorCode = GetLastError();
			errDesc = ErrorDescription(errorCode);
			bool checkError = RetryOnError(errorCode);
			orderType = OrderTypeToString(pType);
			
			// Unrecoverable error
			if(checkError == false)  
			{
				Alert("Open ",orderType," order: Error ",errorCode," - ",errDesc);
				Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",pPrice,", SL: ",pStop,", TP: ",pProfit,", Expiration: ",pExpiration);
				break;
			}
			
			// Retry on error
			else
			{
				Print("Server error detected, retrying...");
				Sleep(RETRY_DELAY);
				retryCount++;
			}
		}
   	
		// Order successful
		else
		{
		   orderType = OrderTypeToString(pType);
		   Comment(orderType," order #",ticket," opened on ",pSymbol);
		   Print(orderType," order #",ticket," opened on ",pSymbol);
		   break;
		} 
	}
   
	// Failed after retry
	if(retryCount > MAX_RETRIES)
	{
		Alert("Open ",orderType," order: Max retries exceeded. Error ",errorCode," - ",errDesc);
		Print("Symbol: ",pSymbol,", Volume: ",pVolume,", Price: ",pPrice,", SL: ",pStop,", TP: ",pProfit,", Expiration: ",pExpiration);
	}

	return(ticket);
}


int TradeManager::OpenBuyStopOrder(string pSymbol,double pVolume,double pPrice,double pStop,double pProfit,string pComment="Buy stop order",datetime pExpiration=0,color pArrow=16711680)
{
   int ticket = OpenPendingOrder(pSymbol, OP_BUYSTOP, pVolume, pPrice, pStop, pProfit, pComment, pExpiration, pArrow);
   return(ticket);
}


int TradeManager::OpenSellStopOrder(string pSymbol,double pVolume,double pPrice,double pStop,double pProfit,string pComment="Sell stop order",datetime pExpiration=0,color pArrow=8519755)
{
   int ticket = OpenPendingOrder(pSymbol, OP_SELLSTOP, pVolume, pPrice, pStop, pProfit, pComment, pExpiration, pArrow);
   return(ticket);
}


int TradeManager::OpenBuyLimitOrder(string pSymbol,double pVolume,double pPrice,double pStop,double pProfit,string pComment="Buy limit order",datetime pExpiration=0,color pArrow=15570276)
{
   int ticket = OpenPendingOrder(pSymbol, OP_BUYLIMIT, pVolume, pPrice, pStop, pProfit, pComment, pExpiration, pArrow);
   return(ticket);
}


int TradeManager::OpenSellLimitOrder(string pSymbol,double pVolume,double pPrice,double pStop,double pProfit,string pComment="Sell limit order",datetime pExpiration=0,color pArrow=15624315)
{
   int ticket = OpenPendingOrder(pSymbol, OP_SELLLIMIT, pVolume, pPrice, pStop, pProfit, pComment, pExpiration, pArrow);
   return(ticket);
}


//+------------------------------------------------------------------+
//| Close market orders                                              |
//+------------------------------------------------------------------+

bool TradeManager::CloseMarketOrder(int pTicket,double pVolume=0.000000,color pArrow=255)
{
   int retryCount = 0;
   int errorCode = 0;
   
   double closePrice = 0;
   double closeVolume = 0;
   
   bool result;
   
   string errDesc;
   
   // Select ticket
   result = OrderSelect(pTicket,SELECT_BY_TICKET);
   
   // Exit with error if order select fails
   if(result == false)
   {
      errorCode = GetLastError();
      errDesc = ErrorDescription(errorCode);
      
      Alert("Close order: Error selecting order #",pTicket,". Error ",errorCode," - ",errDesc);
      return(result);
   }
   
   // Close entire order if pVolume not specified, or if pVolume is greater than order volume
   if(pVolume == 0 || pVolume > OrderLots()) closeVolume = OrderLots();
   else closeVolume = pVolume;
   
	// Order retry loop
	while(retryCount <= MAX_RETRIES)    
	{
		while(IsTradeContextBusy()) Sleep(10);

		// Get current bid/ask price
		if(OrderType() == OP_BUY) closePrice = MarketInfo(OrderSymbol(),MODE_BID);
		else if(OrderType() == OP_SELL) closePrice = MarketInfo(OrderSymbol(),MODE_ASK);

		result = OrderClose(pTicket,closeVolume,closePrice,_slippage,pArrow);

		if(result == false)
		{
			errorCode = GetLastError();
			errDesc = ErrorDescription(errorCode);
			bool checkError = RetryOnError(errorCode);

			// Unrecoverable error
			if(checkError == false)
			{
				Alert("Close order #",pTicket,": Error ",errorCode," - ",errDesc);
				Print("Price: ",closePrice,", Volume: ",closeVolume);
				break;
			}

			// Retry on error
			else
			{
				Print("Server error detected, retrying...");
				Sleep(RETRY_DELAY);
				retryCount++;
			}
		}

		// Order successful
		else
		{
			Comment("Order #",pTicket," closed");
			Print("Order #",pTicket," closed");
			break;
		} 
	}
   
	// Failed after retry
	if(retryCount > MAX_RETRIES)
	{
		Alert("Close order #",pTicket,": Max retries exceeded. Error ",errorCode," - ",errDesc);
		Print("Price: ",closePrice,", Volume: ",closeVolume);
	}
	
	return(result);
}


bool TradeManager::CloseMultipleOrders(CLOSE_MARKET_TYPE pCloseType)
{
   bool error = false;
   bool closeOrder = false;
   
   // Loop through open order pool from oldest to newest
   for(int order = 0; order <= OrdersTotal() - 1; order++)
   {
      // Select order
      bool result = OrderSelect(order,SELECT_BY_POS);
      
      int orderType = OrderType();
      int orderMagicNumber = OrderMagicNumber();
      int orderTicket = OrderTicket();
      double orderVolume = OrderLots();
      
      // Determine if order type matches pCloseType
      if( (pCloseType == CLOSE_ALL_MARKET && (orderType == OP_BUY || orderType == OP_SELL)) 
         || (pCloseType == CLOSE_BUY && orderType == OP_BUY) 
         || (pCloseType == CLOSE_SELL && orderType == OP_SELL) )
      {
         closeOrder = true;
      }
      else closeOrder = false;
      
      // Close order if pCloseType and magic number match currently selected order
      if(closeOrder == true && orderMagicNumber == _magicNumber)
      {
         result = CloseMarketOrder(orderTicket,orderVolume);
         
         if(result == false)
         {
            Print("Close multiple orders: ",OrderTypeToString(orderType)," #",orderTicket," not closed");
            error = true;
         }
         else order--;
      }
   }
   
   return(error);
}


bool TradeManager::CloseAllBuyOrders(void)
{
   bool result = CloseMultipleOrders(CLOSE_BUY);
   return(result);
}


bool TradeManager::CloseAllSellOrders(void)
{
   bool result = CloseMultipleOrders(CLOSE_SELL);
   return(result);
}


bool TradeManager::CloseAllMarketOrders(void)
{
   bool result = CloseMultipleOrders(CLOSE_ALL_MARKET);
   return(result);
}


//+------------------------------------------------------------------+
//| Delete pending orders                                            |
//+------------------------------------------------------------------+

bool TradeManager::DeletePendingOrder(int pTicket,color pArrow=255)
{
   int retryCount = 0;
   int errorCode = 0;
   
   bool result = false;
   
   string errDesc;
  
   // Order retry loop
	while(retryCount <= MAX_RETRIES)    
	{
		while(IsTradeContextBusy()) Sleep(10);
		result = OrderDelete(pTicket,pArrow);
	  
		if(result == false)
		{
			errorCode = GetLastError();
			errDesc = ErrorDescription(errorCode);
			bool checkError = RetryOnError(errorCode);
		
			// Unrecoverable error
			if(checkError == false)
			{
				Alert("Delete pending order #",pTicket,": Error ",errorCode," - ",errDesc);
				break;
			}
			
			// Retry on error
			else
			{
				Print("Server error detected, retrying...");
				Sleep(RETRY_DELAY);
				retryCount++;
			}
		}
	  
		// Order successful
		else
		{
		   Comment("Pending order #",pTicket," deleted");
		   Print("Pending order #",pTicket," deleted");
		   break;
		} 
	}

	// Failed after retry
	if(retryCount > MAX_RETRIES)
	{
		Alert("Delete pending order #",pTicket,": Max retries exceeded. Error ",errorCode," - ",errDesc);
	}

	return(result);
}


bool TradeManager::DeleteMultipleOrders(CLOSE_PENDING_TYPE pDeleteType)
{
   bool error = false;
   bool deleteOrder = false;
   
   // Loop through open order pool from oldest to newest
   for(int order = 0; order <= OrdersTotal() - 1; order++)
   {
      // Select order
      bool result = OrderSelect(order,SELECT_BY_POS);
      
      int orderType = OrderType();
      int orderMagicNumber = OrderMagicNumber();
      int orderTicket = OrderTicket();
      double orderVolume = OrderLots();
      
      // Determine if order type matches pCloseType
      if( (pDeleteType == CLOSE_ALL_PENDING && orderType != OP_BUY && orderType != OP_SELL)
         || (pDeleteType == CLOSE_BUY_LIMIT && orderType == OP_BUYLIMIT) 
         || (pDeleteType == CLOSE_SELL_LIMIT && orderType == OP_SELLLIMIT) 
         || (pDeleteType == CLOSE_BUY_STOP && orderType == OP_BUYSTOP)
         || (pDeleteType == CLOSE_SELL_STOP && orderType == OP_SELLSTOP) )
      {
         deleteOrder = true;
      }
      else deleteOrder = false;
      
      // Close order if pCloseType and magic number match currently selected order
      if(deleteOrder == true && orderMagicNumber == _magicNumber)
      {
         result = DeletePendingOrder(orderTicket);
         
         if(result == false)
         {
            Print("Delete multiple orders: ",OrderTypeToString(orderType)," #",orderTicket," not deleted");
            error = true;
         }
         else order--;
      }
   }
   
   return(error);
}


bool TradeManager::DeleteAllBuyLimitOrders(void)
{
   bool result = DeleteMultipleOrders(CLOSE_BUY_LIMIT);
   return(result);
}


bool TradeManager::DeleteAllBuyStopOrders(void)
{
   bool result = DeleteMultipleOrders(CLOSE_BUY_STOP);
   return(result);
}


bool TradeManager::DeleteAllSellLimitOrders(void)
{
   bool result = DeleteMultipleOrders(CLOSE_SELL_LIMIT);
   return(result);
}


bool TradeManager::DeleteAllSellStopOrders(void)
{
   bool result = DeleteMultipleOrders(CLOSE_SELL_STOP);
   return(result);
}


bool TradeManager::DeleteAllPendingOrders(void)
{
   bool result = DeleteMultipleOrders(CLOSE_ALL_PENDING);
   return(result);
}


//+------------------------------------------------------------------+
//| Set trade properties                                             |
//+------------------------------------------------------------------+

static void TradeManager::SetMagicNumber(int pMagic)
{
   if(_magicNumber != 0)
   {
      Alert("Magic number changed! Any orders previously opened by this expert advisor will no longer be handled!");
   }
   
   _magicNumber = pMagic;
}

static int TradeManager::GetMagicNumber(void)
{
   return(_magicNumber);
}


static void TradeManager::SetSlippage(int pSlippage)
{
   _slippage = pSlippage;
}


//+------------------------------------------------------------------+
//| Internal functions                                               |
//+------------------------------------------------------------------+

bool RetryOnError(int pErrorCode)
{
	// Retry on these error codes
	switch(pErrorCode)
	{
		case ERR_BROKER_BUSY:
		case ERR_COMMON_ERROR:
		case ERR_NO_ERROR:
		case ERR_NO_CONNECTION:
		case ERR_NO_RESULT:
		case ERR_SERVER_BUSY:
		case ERR_NOT_ENOUGH_RIGHTS:
		case ERR_MALFUNCTIONAL_TRADE:
		case ERR_TRADE_CONTEXT_BUSY:
		case ERR_TRADE_TIMEOUT:
		case ERR_REQUOTE:
		case ERR_TOO_MANY_REQUESTS:
		case ERR_OFF_QUOTES:
		case ERR_PRICE_CHANGED:
		case ERR_TOO_FREQUENT_REQUESTS:
		
		return(true);
	}
	
	return(false);
}


string OrderTypeToString(int pType)
{
	string orderType;
	if(pType == OP_BUY) orderType = "Buy";
	else if(pType == OP_SELL) orderType = "Sell";
	else if(pType == OP_BUYSTOP) orderType = "Buy stop";
	else if(pType == OP_BUYLIMIT) orderType = "Buy limit";
	else if(pType == OP_SELLSTOP) orderType = "Sell stop";
	else if(pType == OP_SELLLIMIT) orderType = "Sell limit";
	else orderType = "Invalid order type";
	return(orderType);
}


//+------------------------------------------------------------------+
//| Modify orders                                                    |
//+------------------------------------------------------------------+

bool ModifyOrder(int pTicket, double pPrice, double pStop = 0, double pProfit = 0, datetime pExpiration = 0, color pArrow = clrOrange)
{
	int retryCount = 0;
	int errorCode = 0;

	bool result = false;
	
	string errDesc;
	
	// Order retry loop
	while(retryCount <= MAX_RETRIES)
	{
		while(IsTradeContextBusy()) Sleep(10);
		
		result = OrderModify(pTicket, pPrice, pStop, pProfit, pExpiration, pArrow);
		errorCode = GetLastError();
		
		// Error handling - Ignore error code 1
		if(result == false && errorCode != ERR_NO_RESULT)
		{
			errDesc = ErrorDescription(errorCode);
			bool checkError = RetryOnError(errorCode);
			
			// Unrecoverable error
			if(checkError == false)
			{
				Alert("Modify order #",pTicket,": Error ",errorCode," - ",errDesc);
				Print("Price: ",pPrice,", SL: ",pStop,", TP: ",pProfit,", Expiration: ",pExpiration);
				break;
			}
			
			// Retry on error
			else
			{
				Print("Server error detected, retrying...");
				Sleep(RETRY_DELAY);
				retryCount++;
			}
		}
		
		// Order successful
		else
		{
		   Comment("Order #",pTicket," modified");
		   Print("Order #",pTicket," modified");
		   break;
		} 
	}

	// Failed after retry
	if(retryCount > MAX_RETRIES)
	{
		Alert("Modify order #",pTicket,": Max retries exceeded. Error ",errorCode," - ",errDesc);
		Print("Price: ",pPrice,", SL: ",pStop,", TP: ",pProfit,", Expiration: ",pExpiration);
	}

	return(result);
}


bool ModifyStopsByPoints(int pTicket, int pStopPoints, int pProfitPoints = 0, int pMinPoints = 10)
{
   if(pStopPoints == 0 && pProfitPoints == 0) return false;
   
   bool result = OrderSelect(pTicket,SELECT_BY_TICKET);
   
   if(result == false)
   {
      Print("Modify stops: #",pTicket," not found!");
      return false;
   }
   
   double orderType = OrderType();
   double orderOpenPrice = OrderOpenPrice();
   string orderSymbol = OrderSymbol();
   
   double stopLoss = 0;
   double takeProfit = 0;
   
   if(orderType == OP_BUY)
   {
      stopLoss = BuyStopLoss(orderSymbol,pStopPoints,orderOpenPrice);
      if(stopLoss != 0) stopLoss = AdjustBelowStopLevel(orderSymbol,stopLoss,pMinPoints);
      
      takeProfit = BuyTakeProfit(orderSymbol,pProfitPoints,orderOpenPrice);
      if(takeProfit != 0) takeProfit = AdjustAboveStopLevel(orderSymbol,takeProfit,pMinPoints);
   }
   else if(orderType == OP_SELL)
   {
      stopLoss = SellStopLoss(orderSymbol,pStopPoints,orderOpenPrice);
      if(stopLoss != 0) stopLoss = AdjustAboveStopLevel(orderSymbol,stopLoss,pMinPoints);
      
      takeProfit = SellTakeProfit(orderSymbol,pProfitPoints,orderOpenPrice);
      if(takeProfit != 0) takeProfit = AdjustBelowStopLevel(orderSymbol,takeProfit,pMinPoints);
   }
   
   result = ModifyOrder(pTicket,0,stopLoss,takeProfit);
   return(result);
}


bool ModifyStopsByPrice(int pTicket, double pStopPrice, double pProfitPrice = 0, int pMinPoints = 10)
{
   if(pStopPrice == 0 && pProfitPrice == 0) return false;
   
   bool result = OrderSelect(pTicket,SELECT_BY_TICKET);
   
   if(result == false)
   {
      Print("Modify stops: #",pTicket," not found!");
      return false;
   }
   
   double orderType = OrderType();
   string orderSymbol = OrderSymbol();
   
   double stopLoss = 0;
   double takeProfit = 0;
   
   if(orderType == OP_BUY)
   {
      if(stopLoss != 0) stopLoss = AdjustBelowStopLevel(orderSymbol,pStopPrice,pMinPoints);
      if(takeProfit != 0) takeProfit = AdjustAboveStopLevel(orderSymbol,pProfitPrice,pMinPoints);
   }
   else if(orderType == OP_SELL)
   {
      if(stopLoss != 0) stopLoss = AdjustAboveStopLevel(orderSymbol,pStopPrice,pMinPoints);
      if(takeProfit != 0) takeProfit = AdjustBelowStopLevel(orderSymbol,pProfitPrice,pMinPoints);
   }
   
   result = ModifyOrder(pTicket,0,stopLoss,takeProfit);
   return(result);
}


//+------------------------------------------------------------------+
//| Stop loss & take profit calculation                              |
//+------------------------------------------------------------------+

double BuyStopLoss(string pSymbol,int pStopPoints, double pOpenPrice = 0)
{
	if(pStopPoints <= 0) return(0);
	
	double openPrice;
	int brokerPoint = GetBrokerPoint();
	
	
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLoss = openPrice - (pStopPoints * point * brokerPoint);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	stopLoss = NormalizeDouble(stopLoss,(int)digits);
	
	return(stopLoss);
	
        
}


double SellStopLoss(string pSymbol,int pStopPoints, double pOpenPrice = 0)
{  

	if(pStopPoints <= 0) return(0);
	
	double openPrice;
	int brokerPoint = GetBrokerPoint();
	
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLoss = openPrice + (pStopPoints * point * brokerPoint);

	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	stopLoss = NormalizeDouble(stopLoss,(int)digits);
	
	return(stopLoss);
}


double BuyTakeProfit(string pSymbol,int pProfitPoints, double pOpenPrice = 0)
{   
	if(pProfitPoints <= 0) return(0);
	
	double openPrice;
	int brokerPoint = GetBrokerPoint();
	
	
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double takeProfit = openPrice + (pProfitPoints * point * brokerPoint);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	takeProfit = NormalizeDouble(takeProfit,(int)digits);
	return(takeProfit);

}


double SellTakeProfit(string pSymbol,int pProfitPoints, double pOpenPrice = 0)
{   
   
  
	if(pProfitPoints <= 0) return(0);
	
	double openPrice;
	int brokerPoint = GetBrokerPoint();
	 
	 
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	
	double takeProfit = openPrice - (pProfitPoints * point * brokerPoint);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	takeProfit = NormalizeDouble(takeProfit,(int)digits);
	
	return(takeProfit);
	
	
       //  if (UseTakeProfit) TakeProfitLevel = Bid - TakeProfit * Point * P; else TakeProfitLevel = 0.0;

}


//+------------------------------------------------------------------+
//| Stop level verification                                         |
//+------------------------------------------------------------------+

// Check stop level
bool CheckAboveStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice + stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice >= stopPrice + addPoints) return(true);
	else return(false);
}


bool CheckBelowStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice - stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice <= stopPrice - addPoints) return(true);
	else return(false);
}


// Adjust price to stop level
double AdjustAboveStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice + stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice > stopPrice + addPoints) return(pPrice);
	else
	{
		double newPrice = stopPrice + addPoints;
		Print("Price adjusted above stop level to "+DoubleToString(newPrice));
		return(newPrice);
	}
}


double AdjustBelowStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice - stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice < stopPrice - addPoints) return(pPrice);
	else
	{
		double newPrice = stopPrice - addPoints;
		Print("Price adjusted below stop level to "+DoubleToString(newPrice));
		return(newPrice);
	}
}

int GetBrokerPoint() 
 {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function returns P, which is used for converting pips to decimals/points

   int output;
   if(Digits==5 || Digits==3) output=10;else output=1;
   return(output);

/* Some definitions: Pips vs Point
1 pip = 0.0001 on a 4 digit broker and 0.00010 on a 5 digit broker
1 point = 0.0001 on 4 digit broker and 0.00001 on a 5 digit broker
  
*/

}

int GetYenAdjustFactor() 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function returns a constant factor, which is used for position sizing for Yen pairs

   int output= 1;
   if(Digits == 3|| Digits == 2) output = 100;
   return(output);
  }