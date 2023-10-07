import math

cash = 100
stocks = {
  "VOO": 393.31,

}

def numberPurchasable(cash, stock):
  return math.floor(cash / stock)

def getStockCounts(cash, stocks):
  results = []
  def helper(cash, keys, purchaseCounts):
    name = keys[0]
    price = stocks[name]
    if len(keys) == 1:
      # If there is only one left, max out how many we buy.
      results.append(purchaseCounts
                     + [numberPurchasable(cash, price)])
    else:
      # Iterate over each possible number to purchase.
      for count in range(numberPurchasable(cash, price) + 1):
        helper(cash - (price * count),
               keys[1:],
               purchaseCounts + [count])
  helper(cash, list(stocks.keys()), [])
  return results


def getTotalPrice(stocks, stockCounts):
  keys = list(stocks.keys())
  sum = 0
  for key, count in zip(keys, stockCounts):
    sum += stocks[key] * count
  return round(sum * 100) / 100

results = getStockCounts(cash, stocks)

sortedStockCountResults = sorted(results, key=lambda stockCounts: getTotalPrice(stocks, stockCounts))
for stockCounts in sortedStockCountResults:
  print(stockCounts, getTotalPrice(stocks, stockCounts))

print()
finalResult = stockCounts[-1]
for key, count in zip(stocks.keys(), stockCounts):
  print(key, count)
