//+------------------------------------------------------------------+
//|                                             2ma crossover EA.mq4 |
//|                             Copyright © 2014, fxdaytrader et. al |
//|                             http://ForexFactory.com/fxdaytrader_ |
//|                                            http://ForexBaron.net |
//+------------------------------------------------------------------+
// !!! YOU MUST COMPILE THIS EA WITH THE BUILD 509 COMPILER, download the metaeditor for build 509 at http://www.forexfactory.com/showthread.php?t=470340 !!!
//parts of the code based/taken from code by others (e.g. Steve Hopwood, Baluda, WHRoeder)
#property copyright "Copyright © 2014, fxdaytrader et. al, http://ForexBaron.net"
#property link      "http://ForexBaron.net"
#define EANAME "2ma crossover EA v1.1"

extern bool SendLongTrades  = TRUE;
extern bool SendShortTrades = TRUE;

/////////////////////////////////////////
extern int SignalCandle = 1;

extern  int ma1period = 13;//21;
extern  int ma1shift  = 0; 
extern  int ma1method = MODE_LWMA;
extern  int ma1price  = PRICE_CLOSE;
// 
extern  int ma2period = 21;//55;
extern  int ma2shift  = 0; 
extern  int ma2method = MODE_EMA;
extern  int ma2price  = PRICE_CLOSE;
//
extern bool CloseOnOppositeSignal = TRUE;
extern int  MinBarsBetweenTradesOfSameType = 3;

extern string masfhi =  "Price/Ma filter:";
extern bool UseSingleMaFilter = FALSE;
extern int  singleMaPeriod    = 55;//55;
extern int  singleMaShift     = 3;//3;
extern int  singleMaMethod    = MODE_EMA;//MODE_EMA;
extern int  singleMaPrice     = PRICE_MEDIAN;//PRICE_MEDIAN;
/////////////////////////////////////////

extern double lots         = 1.0;
extern int    MagicNumber  = 12345;//0:manual trades
extern string orderComment = "2ma crossover EA";
extern int    Slippage    = 5;
 bool FilterByMagicNumber    = true;
 bool FilterBySymbol         = true;
extern double SLpips = 90.0;
extern double TPpips = 500.0;
extern string atrhi="--ATR for TP/SL--";
extern bool   UseAtrForSL   = TRUE;
extern bool   UseAtrForTP   = false;
extern int    AtrPeriod     = 14;
extern int    AtrTimeFrame  = 0;
extern double AtrMultiplier = 3.5;
double atrval;

extern string  behi = "---------------------------------------------------------------------";
extern string  BE                            = "----BreakEven settings----";
extern bool    BreakEven                     = TRUE;
extern double  BreakEvenPips                 = 20;
extern double  BreakEvenProfit               = 5;
extern bool    HideBreakEvenStop             = FALSE;
extern double  PipsAwayFromVisualBE          = 50;
extern string  sep1 = "---------------------------------------------------------------------";
extern string  JSL                           = "----JumpingStopLoss settings----";
extern bool    JumpingStop                   = TRUE;
extern double  JumpingStopPips               = 45;
extern bool    AddBEP                        = TRUE; //This adds BreakEvenProfits
extern bool    JumpAfterBreakevenOnly        = TRUE;
extern bool    HideJumpingStop               = FALSE;
extern double  PipsAwayFromVisualJS          = 50;
bool ShowAlerts=false;
bool PrintToJournal=TRUE;
bool CheckForiCustomExist = FALSE;
//
int buys,sells,type;
double ma1,ma2,ma11,ma21;
int Multiplier; double pips2dbl;
bool ForceTradeClosure=false;

//
extern string   tthisep="----------------------------------------------------------------";
//CheckTradingTimes. Baluda has provided all the code for this. Mny thanks Paul; you are a star.
extern string	trh				= "----Trading hours----";
extern string	tr1				= "tradingHours is a comma delimited list";
extern string   tr1a            = "of start and stop times.";
extern string	tr2				= "Prefix start with '+', stop with '-'";
extern string   tr2a            = "Use 24H format.";//, local time.";
extern string	tr3				= "Example: '+07.00,-10.30,+14.15,-16.00'";
extern string	tr3a			    = "Do not leave spaces";
extern string	tr4				= "Blank input means 24 hour trading.";
extern string	tradingHours = "+03.30,-22.59";
extern string	tr5 = "true:LocalTime, false:ServerTime";
extern bool    UseLocalTime = FALSE;//true:TimeLocal(), false:TimeCurrent()
int TradingHourTime;
//close stuff:
extern string tr6 = "you should set the trading hours accordingly to avoid opening trades after that hour!";
extern bool EnableClosingOnEndOfMonth = FALSE;
extern int  EndOfMonthClosingHour     = 23;
extern bool EnableClosingOnEndOfWeek  = TRUE;///FALSE;
extern string tr7 = "(0 means Sunday,1,2,3,4,5,6) of the specified date";
extern int  EndOfWeekDay              = 5;//(0 means Sunday,1,2,3,4,5,6) of the specified date
extern int  EndOfWeekClosingHour      = 23;//you should set the trading hours accordingly to avoid opening trades after that hour!
extern bool EnableDailyClosingAtTime  = FALSE;
extern int  DailyClosingHour          = 23;
////////////////////////////////////////////////////////////////////////////////////////
// trading hours variables
int 	          tradeHours[];
string          tradingHoursDisplay;//tradingHours is reduced to "" on initTradingHours, so this variable saves it for screen display.
bool            TradeTimeOk;
datetime        OldBarsTime,OldDayBarTime;
////////////////////////////////////////////////////////////////////////////////////////

int start() {
   CountOpenTrades(Symbol(),MagicNumber);//1.
   if ((buys+sells)>0) { 
    if (EnableDailyClosingAtTime) CheckForDailyClosingHour();
    if (EnableClosingOnEndOfWeek) CheckForEndOfWeekClosingHour();
    if (EnableClosingOnEndOfMonth) CheckForLastEndMonthClosingHour();
    if (ForceTradeClosure) CloseAllTrades(Symbol(),MagicNumber);
    if(BreakEven) BreakEvenStopLoss();
    if(JumpingStop) JumpingStopLoss();
   }
   GetIndicatorValues();
   
   if (CloseOnOppositeSignal && type==OP_BUY) CloseTrades(Symbol(),MagicNumber,OP_SELL);
   if (CloseOnOppositeSignal && type==OP_SELL) CloseTrades(Symbol(),MagicNumber,OP_BUY);
   CountOpenTrades(Symbol(),MagicNumber);//2.
   
   atrval = iATR(Symbol(),AtrTimeFrame,AtrPeriod,SignalCandle);
   TradeTimeOk = CheckTradingTimes();
   if (TradeTimeOk) if (type!= 99 && buys==0 && sells==0) {
    RefreshRates();
    double sl=0.0;
    double tp=0.0;
    if (SendLongTrades) if (OCTimeLastOrderSameTypeOk(Symbol(),OP_BUY,MagicNumber)) if (type==OP_BUY)  {
      if (!UseAtrForSL && SLpips!=0.0) sl = Ask-SLpips*pips2dbl;
      if (!UseAtrForTP && TPpips!=0.0) tp = Ask+TPpips*pips2dbl;
      if (UseAtrForSL) sl = Ask-(atrval*AtrMultiplier);
      if (UseAtrForTP) tp = Ask+(atrval*AtrMultiplier);
     OrderSend2Stage(Symbol(),OP_BUY,lots,Ask,Slippage,sl,tp,orderComment,MagicNumber,0,CLR_NONE);
    }
    if (SendShortTrades) if (OCTimeLastOrderSameTypeOk(Symbol(),OP_BUY,MagicNumber)) if (type==OP_SELL) {
      if (!UseAtrForSL && SLpips!=0.0) sl = Bid+SLpips*pips2dbl;
      if (!UseAtrForTP && TPpips!=0.0) tp = Bid-TPpips*pips2dbl;
      if (UseAtrForSL) sl = Bid+(atrval*AtrMultiplier);
      if (UseAtrForTP) tp = Bid-(atrval*AtrMultiplier);
     OrderSend2Stage(Symbol(),OP_SELL,lots,Bid,Slippage,sl,tp,orderComment,MagicNumber,0,CLR_NONE);
    }
   }
 DisplayScreenComment();
}

//+------------------------------------------------------------------+

int deinit() {
 Comment("");
 return(0);
}

int init()  {
 BrokerDigitAdjust(Symbol()); 
  //Set up the trading hours
 tradingHoursDisplay = tradingHours;//For display
 initTradingHours();//Sets up the trading hours arra
 return(0);
}

void CountOpenTrades(string symbol,int magicnumber) {
 buys=0;
 sells=0;
 for (int cnt=OrdersTotal()-1; cnt>=0; cnt--) {
  if (!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES)) continue;
  if (FilterBySymbol && OrderSymbol()!=symbol) continue;
  if (FilterByMagicNumber && OrderMagicNumber()!=magicnumber) continue;
   {
     if (OrderType()==OP_BUY) buys++;
     if (OrderType()==OP_SELL) sells++;
    }
  }
}

void CloseTrades(string symbol,int magicnumber,int type) {
 bool result;
 for (int cnt=OrdersTotal()-1; cnt>=0; cnt--) {
  if (!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES)) continue;
  if (FilterBySymbol && OrderSymbol()!=symbol) continue;
  if (FilterByMagicNumber && OrderMagicNumber()!=magicnumber) continue;
   {
     RefreshRates();
     if (OrderType()==OP_BUY && type==OP_BUY)   result = OrderClose(OrderTicket(),OrderLots(),Bid,99999,CLR_NONE);
     if (OrderType()==OP_SELL && type==OP_SELL) result = OrderClose(OrderTicket(),OrderLots(),Ask,99999,CLR_NONE);
    }
  }
}

void BrokerDigitAdjust(string symbol) {
 Multiplier = 1;
 if (MarketInfo(symbol,MODE_DIGITS) == 3 || MarketInfo(symbol,MODE_DIGITS) == 5) Multiplier = 10;
 if (MarketInfo(symbol,MODE_DIGITS) == 6) Multiplier = 100;   
 if (MarketInfo(symbol,MODE_DIGITS) == 7) Multiplier = 1000;
 pips2dbl = Multiplier*MarketInfo(symbol,MODE_POINT);
 Slippage*=Multiplier;
}

bool OrderSend2Stage(string symbol,int type,double lots,double price,int slippage,double sl,double tp,string ocomment,int magic,datetime expiry,color col) {
 while (IsTradeContextBusy()) Sleep(100);
 bool result=true;
 RefreshRates();
 int ticket=OrderSend(symbol,type,lots,price,slippage,0,0,ocomment,magic,expiry,col); 
  if (!OrderSelect(ticket, SELECT_BY_TICKET)) return(false);
   if (sl!=0.00000 && tp!=0.00000) result = OrderModify(OrderTicket(),OrderOpenPrice(),sl,tp,OrderExpiration(),CLR_NONE);
   if (sl!=0.00000 && tp==0.00000) result = OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),OrderExpiration(),CLR_NONE);
   if (sl==0.00000 && tp!=0.00000) result = OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),tp,OrderExpiration(),CLR_NONE);
 return(result);
}

void BreakEvenStopLoss() {// Move stop loss to breakeven, based upon/taken from mptm global ea

double ask = MarketInfo(OrderSymbol(),MODE_ASK);
double bid = MarketInfo(OrderSymbol(),MODE_BID);

   //Check hidden BE for trade closure
   if (HideBreakEvenStop)
   {
      bool TradeClosed = CheckForHiddenStopLossHit(OrderType(), PipsAwayFromVisualBE, OrderStopLoss() );
      if (TradeClosed) return;//Trade has closed, so nothing else to do
   }//if (HideBreakEvenStop)
   bool result;

   if (OrderType()==OP_BUY)
         {
            if (bid >= OrderOpenPrice () + (BreakEvenPips * pips2dbl) &&
                OrderStopLoss()<OrderOpenPrice())
            {
               result = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(BreakEvenProfit * pips2dbl),OrderTakeProfit(),0,CLR_NONE);
               if (result && ShowAlerts==true) Alert("Breakeven set on ", OrderSymbol(), " ticket no ", OrderTicket());
               if (PrintToJournal) Print("Breakeven set on ", OrderSymbol(), " ticket no ", OrderTicket());
               if (!result)
               {
                  int err=GetLastError();
                  if (ShowAlerts==true) Alert("Setting of breakeven SL ", OrderSymbol(), " ticket no ", OrderTicket()," failed with error (",err,")");
                  if (PrintToJournal) Print("Setting of breakeven SL ", OrderSymbol(), " ticket no ", OrderTicket()," failed with error (",err,")");
               }//if !result && ShowAlerts)
            }
   	   }

   if (OrderType()==OP_SELL)
         {
           if (ask <= OrderOpenPrice() - (BreakEvenPips * pips2dbl) &&
              (OrderStopLoss()>OrderOpenPrice()|| OrderStopLoss()==0))
            {
               result = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(BreakEvenProfit * pips2dbl),OrderTakeProfit(),0,CLR_NONE);
               if (result && ShowAlerts==true) Alert("Breakeven set on ", OrderSymbol(), " ticket no ", OrderTicket());
               if (PrintToJournal) Print("Breakeven set on ", OrderSymbol(), " ticket no ", OrderTicket());
               if (!result && ShowAlerts)
               {
                  err=GetLastError();
                  if (ShowAlerts==true) Alert("Setting of breakeven SL ", OrderSymbol(), " ticket no ", OrderTicket()," failed with error (",err,")");
                  if (PrintToJournal) Print("Setting of breakeven SL ", OrderSymbol(), " ticket no ", OrderTicket()," failed with error (",err,")");
               }//if !result && ShowAlerts)
            }
         }

} // End BreakevenStopLoss sub

bool CheckForHiddenStopLossHit(int type, double iPipsAboveVisual, double stop ) { //based upon/taken from mptm global ea
   //Reusable code that can be called by any of the stop loss manipulation routines except HiddenStopLoss().
   //Checks to see if the market has hit the hidden sl and attempts to close the trade if so.
   //Returns true if trade closure is successful, else returns false

double ask = MarketInfo(OrderSymbol(),MODE_ASK);
double bid = MarketInfo(OrderSymbol(),MODE_BID);

   //Check buy trade
   if (type == OP_BUY)
   {
      double sl = NormalizePrice(OrderSymbol(),(stop + (iPipsAboveVisual * pips2dbl)));
      if (bid <= sl)
      {
         bool result = OrderClose(OrderTicket(), OrderLots(), bid, 99999, CLR_NONE);//OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 5, CLR_NONE);
         if (result)
         {
            if (ShowAlerts==true) Alert("Stop loss hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());
         }//if (result)
         else
         {
            int err=GetLastError();
            if (ShowAlerts==true) Alert("Stop loss hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket()," failed with error (",err,")");
            if (PrintToJournal) Print("Stop loss hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket()," failed with error (",err,")");
         }//else
      }//if (bid <= sl)
   }//if (type = OP_BUY)

   //Check buy trade
   if (type == OP_SELL)
   {
      sl = NormalizePrice(OrderSymbol(),(stop - (iPipsAboveVisual * pips2dbl)));
      if (ask >= sl)
      {
         result = OrderClose(OrderTicket(), OrderLots(), ask, 99999, CLR_NONE);//OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 5, CLR_NONE);
         if (result)
         {
            if (ShowAlerts==true) Alert("Stop loss hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket());
         }//if (result)
         else
         {
            err=GetLastError();
            if (ShowAlerts==true) Alert("Stop loss hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket()," failed with error (",err,")");
            if (PrintToJournal) Print("Stop loss hit. Close of ", OrderSymbol(), " ticket no ", OrderTicket()," failed with error (",err,")");
         }//else
      }//if (ask >= sl)
   }//if (type = OP_SELL)

   return(result);


}//End bool CheckForHiddenStopLossHit(int type, double iPipsAboveVisual, double stop )

void JumpingStopLoss() {//based upon/taken from mptm global ea
double ask = MarketInfo(OrderSymbol(),MODE_ASK);
double bid = MarketInfo(OrderSymbol(),MODE_BID);
   // Jump sl by pips and at intervals chosen by user .
   // Also carry out partial closure if the user requires this
   // Abort the routine if JumpAfterBreakevenOnly is set to true and be sl is not yet set
   if (JumpAfterBreakevenOnly && OrderType()==OP_BUY)
   {
      if(OrderStopLoss()<OrderOpenPrice()) return(0);
   }

   if (JumpAfterBreakevenOnly && OrderType()==OP_SELL)
   {
      if(OrderStopLoss()>OrderOpenPrice()) return(0);
   }

   double sl=OrderStopLoss(); //Stop loss

   if (OrderType()==OP_BUY)
   {
      //Check hidden js for trade closure
      if (HideJumpingStop)
      {
         bool TradeClosed = CheckForHiddenStopLossHit(OP_BUY, PipsAwayFromVisualJS, OrderStopLoss() );
         if (TradeClosed) return;//Trade has closed, so nothing else to do
      }//if (HideJumpingStop)

      // First check if sl needs setting to breakeven
      if (sl==0 || sl<OrderOpenPrice())
      {
         if (ask >= OrderOpenPrice() + (JumpingStopPips * pips2dbl))
         {
            sl=OrderOpenPrice();
            if (AddBEP==true) sl=sl+(BreakEvenProfit * pips2dbl); // If user wants to add a profit to the break even
            bool result = OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,CLR_NONE);
            if (result)
            {
               if (ShowAlerts==true) Alert("Jumping stop set at breakeven ",sl, " ", OrderSymbol(), " ticket no ", OrderTicket());
               if (PrintToJournal) Print("Jumping stop set at breakeven :  ", OrderSymbol(), " :  SL ", sl, " :  Ask ", ask);
            }//if (result)
            if (!result)
            {
               int err=GetLastError();
               if (ShowAlerts) Alert(OrderSymbol(), " buy trade. Jumping stop function failed to set SL at breakeven, with error(",err,")");
               if (PrintToJournal) Print(OrderSymbol(), " buy trade. Jumping stop function failed to set SL at breakeven, with error(",err,")");
            }//if (!result)

            return(0);
         }//if (ask >= OrderOpenPrice() + (JumpingStopPips * pips2dbl))
      } //close if (sl==0 || sl<OrderOpenPrice()


      // Increment sl by sl + JumpingStopPips.
      // This will happen when market price >= (sl + JumpingStopPips)
      if (bid>= sl + ((JumpingStopPips*2) * pips2dbl) && sl>= OrderOpenPrice())
      {
         sl=sl+(JumpingStopPips * pips2dbl);
         result = OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,CLR_NONE);
         if (result)
         {
            if (ShowAlerts==true) Alert("Jumping stop set at ",sl, " ", OrderSymbol(), " ticket no ", OrderTicket());
            if (PrintToJournal) Print("Jumping stop set :  ", OrderSymbol(), " :  SL ", sl, " :  Ask ", ask);
         }//if (result)
         if (!result)
         {
            err=GetLastError();
            if (ShowAlerts) Alert(OrderSymbol(), " buy trade. Jumping stop function failed with error(",err,")");
            if (PrintToJournal) Print(OrderSymbol(), " buy trade. Jumping stop function failed with error(",err,")");
         }//if (!result)

      }// if (bid>= sl + (JumpingStopPips * pips2dbl) && sl>= OrderOpenPrice())
   }//if (OrderType()==OP_BUY)

   if (OrderType()==OP_SELL)
   {
      //Check hidden js for trade closure
      if (HideJumpingStop)
      {
         TradeClosed = CheckForHiddenStopLossHit(OP_SELL, PipsAwayFromVisualJS, OrderStopLoss() );
         if (TradeClosed) return;//Trade has closed, so nothing else to do
      }//if (HideJumpingStop)

      // First check if sl needs setting to breakeven
      if (sl==0 || sl>OrderOpenPrice())
      {
         if (ask <= OrderOpenPrice() - (JumpingStopPips * pips2dbl))
         {
            sl = OrderOpenPrice();
            if (AddBEP==true) sl=sl-(BreakEvenProfit * pips2dbl); // If user wants to add a profit to the break even
            result = OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,CLR_NONE);
            if (result)
            {
            }//if (result)
            if (!result)
            {
               err=GetLastError();
               if (ShowAlerts) Alert(OrderSymbol(), " sell trade. Jumping stop function failed to set SL at breakeven, with error(",err,")");
               if (PrintToJournal) Print(OrderSymbol(), " sell trade. Jumping stop function failed to set SL at breakeven, with error(",err,")");
            }//if (!result)

            return(0);
         }//if (ask <= OrderOpenPrice() - (JumpingStopPips * pips2dbl))
      } // if (sl==0 || sl>OrderOpenPrice()

      // Decrement sl by sl - JumpingStopPips.
      // This will happen when market price <= (sl - JumpingStopPips)
      if (bid<= sl - ((JumpingStopPips*2) * pips2dbl) && sl<= OrderOpenPrice())
      {
         sl=sl-(JumpingStopPips * pips2dbl);
         result = OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,CLR_NONE);
         if (result)
         {
            if (ShowAlerts==true) Alert("Jumping stop set at ",sl, " ", OrderSymbol(), " ticket no ", OrderTicket());
            if (PrintToJournal) Print("Jumping stop set :  ", OrderSymbol(), " :  SL ", sl, " :  Ask ", ask);
         }//if (result)
         if (!result)
         {
            err=GetLastError();
            if (ShowAlerts) Alert(OrderSymbol(), " sell trade. Jumping stop function failed with error(",err,")");
            if (PrintToJournal) Print(OrderSymbol(), " sell trade. Jumping stop function failed with error(",err,")");
         }//if (!result)

      }// close if (bid>= sl + (JumpingStopPips * pips2dbl) && sl>= OrderOpenPrice())
   }//if (OrderType()==OP_SELL)

}//End of JumpingStopLoss sub

//Open price for pending order must be adjusted to be a multiple of ticksize, not point, and on metals they are not the same.
//see also http://forum.mql4.com/45425#564188
double NormalizePrice(string symbol, double price) {
 double ts = MarketInfo(symbol,MODE_TICKSIZE);
return(MathRound(price/ts)*ts );
}

bool IsSingleMaFilterBull() {
 if (!UseSingleMaFilter) return(true);
 double singlema = iMA(Symbol(),0,singleMaPeriod,singleMaShift,singleMaMethod,singleMaPrice,SignalCandle);
 double cclose   = iClose(Symbol(),0,SignalCandle);
 if (cclose>singlema) return(true);
 return(false);
}

bool IsSingleMaFilterBear() {
 if (!UseSingleMaFilter) return(true);
 double singlema = iMA(Symbol(),0,singleMaPeriod,singleMaShift,singleMaMethod,singleMaPrice,SignalCandle);
 double cclose   = iClose(Symbol(),0,SignalCandle);
 if (cclose<singlema) return(true);
 return(false);
}

//////////////////////////////////////////////////////////////////
//trading hours, by Steve Hopwood and Baluda
bool CheckTradingTimes() 
{
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// Trade 24 hours if no input is given
	if ( ArraySize( tradeHours ) == 0 ) return ( true );

	// Get local time in minutes from midnight
    if (UseLocalTime) TradingHourTime = TimeLocal();
     else if (!UseLocalTime) TradingHourTime = TimeCurrent();
    int time = TimeHour(TradingHourTime) * 60 + TimeMinute(TradingHourTime);
   
	// Don't you love this?
	int i = 0;
	while ( time >= tradeHours[i] ) 
	{	
		if ( i == ArraySize( tradeHours ) ) break;
		i++;		
	}
	if ( i % 2 == 1 ) return ( true );
	return ( false );

}//End bool CheckTradingTimes() 

//+------------------------------------------------------------------+
//| Initialize Trading Hours Array                                   |
//+------------------------------------------------------------------+
bool initTradingHours() 
{
   // Called from init()
   
	// Assume 24 trading if no input found
	if ( tradingHours == "" )	
	{
		ArrayResize( tradeHours, 0 );
		return ( true );
	}

	int i;

	// Add 00:00 start time if first element is stop time
	if ( StringSubstr( tradingHours, 0, 1 ) == "-" ) 
	{
		tradingHours = StringConcatenate( "+0,", tradingHours );   
	}
	
	// Add delimiter
	if ( StringSubstr( tradingHours, StringLen( tradingHours ) - 1) != "," ) 
	{
		tradingHours = StringConcatenate( tradingHours, "," );   
	}
	
	string lastPrefix = "-";
	i = StringFind( tradingHours, "," );
	
	while (i != -1) {

		// Resize array
		int size = ArraySize( tradeHours );
		ArrayResize( tradeHours, size + 1 );

		// Get part to process
		string part = StringSubstr( tradingHours, 0, i );

		// Check start or stop prefix
		string prefix = StringSubstr ( part, 0, 1 );
		if ( prefix != "+" && prefix != "-" ) 
		{
			Print("ERROR IN TRADINGHOURS INPUT (NO START OR CLOSE FOUND), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}

		if ( ( prefix == "+" && lastPrefix == "+" ) || ( prefix == "-" && lastPrefix == "-" ) )	
		{
			Print("ERROR IN TRADINGHOURS INPUT (START OR CLOSE IN WRONG ORDER), ASSUME 24HOUR TRADING.");
			ArrayResize ( tradeHours, 0 );
			return ( true );
		}
		
		lastPrefix = prefix;

		// Convert to time in minutes
		part = StringSubstr( part, 1 );
		double time = StrToDouble( part );
		int hour = MathFloor( time );
		int minutes = MathRound( ( time - hour ) * 100 );

		// Add to array
		tradeHours[size] = 60 * hour + minutes;

		// Trim input string
		tradingHours = StringSubstr( tradingHours, i + 1 );
		i = StringFind( tradingHours, "," );
	}

	return ( true );
}//End bool initTradingHours() 
//end trading hours
////////////////////////////////////////////////////////////////

string bool2txt(int lbool) {
 if (lbool==true) return("yes");
 if (lbool==false) return("no");
 return("%");
}

bool OCTimeLastOrderSameTypeOk(string symbol,int type,int magicnumber) {
 if (MinBarsBetweenTradesOfSameType==0) return(true);
 for (int cnt=OrdersHistoryTotal()-1; cnt>=0; cnt--) {
  if (!OrderSelect(cnt,SELECT_BY_POS,MODE_HISTORY)) continue;
  if (OrderSymbol()!=symbol) continue;
  if (OrderMagicNumber()!=magicnumber) continue;
  if (OrderType()!=type) continue;
   {//start loop
     if (TimeCurrent() - OrderCloseTime() < (MinBarsBetweenTradesOfSameType * Period() * 60)) return(false);
   }//end loop
 }//for (int cnt=OrdersTotal()-1; cnt>=0; cnt--) {
return(true);
}

void DisplayScreenComment() {
Comment(EANAME+", © 2014, Marc (fxdaytrader) et. al *** http://ForexBaron.net"+"\n"+
  " :: server: "+AccountServer()+", broker: "+AccountCompany()+"\n\n"+
  "  fastMA: "+ma1period+", slowMA: "+ma2period+"\n"+
  "  SendLongTrades="+bool2txt(SendLongTrades)+", SendShortTrades="+bool2txt(SendShortTrades)+"\n"+
  "  CloseOnOppositeSignal="+bool2txt(CloseOnOppositeSignal)+", UseSingleMaFilter("+singleMaPeriod+")="+bool2txt(UseSingleMaFilter)+"\n"+
  "  MinBarsBetweenTradesOfSameType="+MinBarsBetweenTradesOfSameType+", MagicNumber="+MagicNumber+", lots="+DoubleToStr(lots,2)+"\n"+
  "  UseAtrForSL="+bool2txt(UseAtrForSL)+", UseAtrForTP="+bool2txt(UseAtrForTP)+", atr="+DoubleToStr((atrval/pips2dbl),2)+" pips"+"\n"+
  "  SLpips="+DoubleToStr(SLpips,2)+", TPpips="+DoubleToStr(TPpips,2)+", BreakEven="+bool2txt(BreakEven)+" (pips="+DoubleToStr(BreakEvenPips,2)+", profit="+DoubleToStr(BreakEvenProfit,2)+"), JumpingStop="+bool2txt(JumpingStop)+" (pips="+DoubleToStr(JumpingStopPips,2)+")"+"\n"+
  "  Trading Hours (local time="+bool2txt(UseLocalTime)+"): "+tradingHoursDisplay+" (inside trading hours="+bool2txt(TradeTimeOk)+"), EnableDailyClosingAtTime(hour:"+DailyClosingHour+")="+bool2txt(EnableDailyClosingAtTime)+"\n"+
  "  EnableClosingOnEndOfWeek(day:"+Day2Txt(EndOfWeekDay)+",hour:"+EndOfWeekClosingHour+")="+bool2txt(EnableClosingOnEndOfWeek)+", EnableClosingOnEndOfMonth(day:"+GetLastDayOfMonth()+",hour:"+EndOfMonthClosingHour+")="+bool2txt(EnableClosingOnEndOfMonth)+"\n");
}

void CheckForDailyClosingHour() {
   static int OldDailyClosingBarTime=0;
   
   if (UseLocalTime) TradingHourTime = TimeLocal();
    else if (!UseLocalTime) TradingHourTime = TimeCurrent();
   
   if (EnableDailyClosingAtTime) {
    if (TimeHour(TradingHourTime) >= DailyClosingHour) if (OldDailyClosingBarTime != iTime(NULL,PERIOD_D1,0)) {
     OldDailyClosingBarTime = iTime(NULL,PERIOD_D1,0);
     ForceTradeClosure=true;
    }//if (OldDailyClosingBarTime != iTime(NULL,PERIOD_D1, 0)) {
   }//if (EnableDailyClosingAtTime) {
}

void CheckForEndOfWeekClosingHour() {
   static int OldEndOfWeekClosingBarTime=0;
   
   if (UseLocalTime) TradingHourTime = TimeLocal();
    else if (!UseLocalTime) TradingHourTime = TimeCurrent();

   if (EnableClosingOnEndOfWeek && TimeDayOfWeek(TradingHourTime)==EndOfWeekDay) if (TimeHour(TradingHourTime) >= EndOfWeekClosingHour) 
    if (OldEndOfWeekClosingBarTime != iTime(NULL,PERIOD_W1,0)) {
     OldEndOfWeekClosingBarTime = iTime(NULL,PERIOD_W1,0);
     ForceTradeClosure=true;
   }
}

string Day2Txt(int type) {
//(0 means Sunday,1,2,3,4,5,6) of the specified date
 switch(type) {
  case 0     : return("sunday");    break;
  case 1     : return("monday");    break;
  case 2     : return("tuesday");   break;
  case 3     : return("wednesday"); break;
  case 4     : return("thursday");  break;
  case 5     : return("friday");    break;
  case 5     : return("saturday");  break;
  default    : return("unknown");
 }
 return("UNKNOWN");
}

//function (IsLeapYear, DaysOfMonth) by WHRoeder, http://forum.mql4.com/51054#691229
void CheckForLastEndMonthClosingHour() {
 if (UseLocalTime) TradingHourTime = TimeLocal();
  else if (!UseLocalTime) TradingHourTime = TimeCurrent();
  if (EnableClosingOnEndOfMonth && TimeDay(TradingHourTime)==GetLastDayOfMonth()) if (TimeHour(TradingHourTime) >= EndOfMonthClosingHour) ForceTradeClosure=true;
}

int GetLastDayOfMonth() {
 if (UseLocalTime) TradingHourTime = TimeLocal();
  else if (!UseLocalTime) TradingHourTime = TimeCurrent();
 return(DaysOfMonth(TradingHourTime));
}

bool IsLeapYear(int year) {
 return(year%4==0 && year%100!=0 && year%400==0);
}

int DaysOfMonth(datetime when) {
 // Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
 static int dpm[] ={31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31  };
 int iDpm = TimeMonth(when) - 1;
 if (iDpm != 1)  return(dpm[iDpm]);
 return(dpm[iDpm] + IsLeapYear(TimeYear(when)));
}

bool CloseAllTrades(string symbol,int magicnumber) {
 bool result;
 ForceTradeClosure=false;
 for (int cnt=OrdersTotal()-1; cnt>=0; cnt--) {
  if (!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES)) continue;
  if (FilterBySymbol && OrderSymbol()!=symbol) continue;
  if (FilterByMagicNumber && OrderMagicNumber()!=magicnumber) continue;
   {  
     Print("CloseAllTrades(): Closing all open orders ...");
     while (IsTradeContextBusy()) Sleep(100);
     RefreshRates();
     if (OrderType()==OP_BUY)  result = OrderClose(OrderTicket(),OrderLots(),Bid,99999,CLR_NONE);
     if (OrderType()==OP_SELL) result = OrderClose(OrderTicket(),OrderLots(),Ask,99999,CLR_NONE);
     if(OrderType()>OP_SELL && OrderType()<=OP_SELLSTOP) result = OrderDelete(OrderTicket());//delete pending orders      
     if (!result) ForceTradeClosure=true;
   }
  }//for (int cnt=OrdersTotal()-1; cnt>=0; cnt--) {
}//End void CloseAllTrades()

void GetIndicatorValues() {
 type=99;//nothing, neutral

 ma1 = iMA(Symbol(),0,ma1period,ma1shift,ma1method,ma1price,SignalCandle);
 ma11 = iMA(Symbol(),0,ma1period,ma1shift,ma1method,ma1price,SignalCandle+1);

 ma2 = iMA(Symbol(),0,ma2period,ma2shift,ma2method,ma2price,SignalCandle);
 ma21 = iMA(Symbol(),0,ma2period,ma2shift,ma2method,ma2price,SignalCandle+1);


 if (IsSingleMaFilterBull()) if(ma1>ma2 && ma11<ma21) type = OP_BUY;
 if (IsSingleMaFilterBear()) if(ma1<ma2 && ma11>ma21) type = OP_SELL;
}

