---
layout: news_item
title: "Ion .NET 1.1.0 Released"
date: 2020-11-23
categories: news ion-dotnet
---
This release includes:

* Replacing the usage of decimal#TryParse(String, Decimal) with decimal#TryParse(String, NumberStyles, IFormatProvider, Decimal), allowing us to use InvariantCulture instead of the current thread's configured culture. ([#129](https://github.com/amzn/ion-dotnet/pull/129))
* Adding a JSON text writer. ([#130](https://github.com/amzn/ion-dotnet/pull/130))
* Moving to GitHub Actions for CI build. ([#124](https://github.com/amzn/ion-dotnet/pull/124))

The Amazon.IonDotnet package is available via [NuGet](https://www.nuget.org/packages/Amazon.IonDotnet).

| [Release Notes](https://github.com/amzn/ion-dotnet/releases/tag/v1.1.0) | [Ion .NET](https://github.com/amzn/ion-dotnet) |

