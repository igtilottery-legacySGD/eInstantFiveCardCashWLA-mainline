<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					var bonusTotal = 0; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var playerHands = getPlayerHands(scenario);
						var luckyHand = getLuckyHand(scenario);
						var bonusTriggerHand = getBonusTriggerHand(scenario);
						var bonusCard = getBonusCards(scenario);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');

						////////////////////
						// Parse scenario //
						////////////////////

						const rankText = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
						const suitText = ['&clubs;','&diams;','&hearts;','&spades;'];
						var playerHandCards = [];
						var luckyHandCards = [];
						var playerHandOutcome = [];
						var handWinsLuckyHand = [];
						var rankCounts = [];
						var suitCounts = [];
						var cardNum = 0;
						var rankNum = 0;
						var suitNum = 0;
						var lowestRank = 0;
						var isStraight = false;
						var luckyHandMatches = [];
						var luckyHandCardWin = [0,0,0,0,0];

						for (var card=0; card<5; card++)
						{
							cardNum = parseInt(luckyHand[card]);
							rankNum = (cardNum - 1) % 13;
							suitNum = parseInt((cardNum - 1) / 13);

							luckyHandCards[card] = rankText[rankNum] + suitText[suitNum];
						}

						for (var hand=0; hand<6; hand++)
						{
							playerHandCards[hand] = [];
							playerHandOutcome[hand] = '';
							handWinsLuckyHand[hand] = false;

							rankCounts = [0,0,0,0,0,0,0,0,0,0,0,0,0];
							suitCounts = [0,0,0,0];

							for (var card=0; card<5; card++)
							{
								cardNum = parseInt(playerHands[hand][card]);
								rankNum = (cardNum - 1) % 13;
								suitNum = parseInt((cardNum - 1) / 13);

								rankCounts[rankNum]++;
								suitCounts[suitNum]++;

								playerHandCards[hand][card] = rankText[rankNum] + suitText[suitNum];
							}

							isStraight = false;
							lowestRank = rankCounts.indexOf(1);

							if (rankCounts[lowestRank+1] == 1 && rankCounts[lowestRank+2] == 1 && rankCounts[lowestRank+3] == 1 && rankCounts[lowestRank+4] == 1)
							{
								isStraight = true;
							}

							if (suitCounts.indexOf(5) != -1)
							{
								if (rankCounts[0] == 1 && rankCounts[9] == 1 && rankCounts[10] == 1 && rankCounts[11] == 1 && rankCounts[12] == 1)
								{
									playerHandOutcome[hand] = 'A';
								}
								else
								{
									if (isStraight)
									{
										playerHandOutcome[hand] = 'B';
									}
									else
									{
										playerHandOutcome[hand] = 'E';
									}
								}
							}
							else if (rankCounts.indexOf(4) != -1)
							{
								playerHandOutcome[hand] = 'C';
							}
							else if (rankCounts.indexOf(3) != -1 && rankCounts.indexOf(2) != -1)
							{
								playerHandOutcome[hand] = 'D';
							}
							else if (isStraight)
							{
								playerHandOutcome[hand] = 'F';
							}
							else if (rankCounts.indexOf(3) != -1)
							{
								playerHandOutcome[hand] = 'G';
							}
							else if (rankCounts.indexOf(2) != -1 && rankCounts.indexOf(2) != rankCounts.lastIndexOf(2))
							{
								playerHandOutcome[hand] = 'H';
							}

							luckyHandMatches[hand] = 0;

							for (var card=0; card<5; card++)
							{
								if ((playerHands[hand]).indexOf(luckyHand[card]) != -1)
								{
									luckyHandMatches[hand]++;
								}
							}

							if (luckyHandMatches[hand] > 1)
							{
								playerHandOutcome[hand] = 'L';
								handWinsLuckyHand[hand] = true;

								for (var card=0; card<5; card++)
								{
									if ((playerHands[hand]).indexOf(luckyHand[card]) != -1)
									{
										luckyHandCardWin[card] = hand + 1;
									}
								}
							}
						}

						playerHandOutcome[bonusTriggerHand-1] = (bonusTriggerHand != 0) ? 'TriggerBonus' : '';

						/////////////////////////
						// Output Player Hands //
						/////////////////////////

						var r = [];
						var cardText = '';
						var outcomeText = '';
						var prizeText = '';

						r.push('<p>' + getTranslationByName("playerHands", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td style="padding-right:10px">' + getTranslationByName("playerHand", translations) + '</td>');
						r.push('<td style="padding-right:10px">' + getTranslationByName("playerCards", translations) + '</td>');
						r.push('<td style="padding-right:10px">' + getTranslationByName("handOutcome", translations) + '</td>');
						r.push('<td style="padding-right:10px">' + getTranslationByName("handPrize", translations) + '</td>');
						r.push('</tr>');

						for (var i=0; i<6; i++)
						{
							cardText = '';

							for (var j=0; j<5; j++)
							{
								cardText += ((cardText != '') ? ' ' : '') + playerHandCards[i][j];
							}

							outcomeText = (playerHandOutcome[i] != '') ? getTranslationByName('prize'+playerHandOutcome[i], translations) : '';
							outcomeText += (handWinsLuckyHand[i]) ? ' : ' + (luckyHandMatches[i]).toString() : '';

							prizeText = playerHandOutcome[i] + ((handWinsLuckyHand[i]) ? (luckyHandMatches[i]).toString() : '');
							prizeText = ((playerHandOutcome[i]).length == 1) ? prizeText : '';
							prizeText = (prizeText != '') ? convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)] : '';

							r.push('<tr class="tablebody">');
							r.push('<td style="padding-right:10px">' + (i+1).toString() + '</td>');
							r.push('<td style="padding-right:10px">' + cardText + '</td>');
							r.push('<td style="padding-right:10px">' + outcomeText + '</td>');
							r.push('<td style="padding-right:10px">' + prizeText + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');

						///////////////////////
						// Output Lucky Hand //
						///////////////////////

						r.push('<p>' + getTranslationByName("luckyHandGame", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td style="padding-right:10px">' + getTranslationByName("luckyHandCard", translations) + '</td>');
						r.push('<td style="padding-right:10px">' + getTranslationByName("luckyHandOutcome", translations) + '</td>');
						r.push('</tr>');

						for (var i=0; i<5; i++)
						{
							cardText = luckyHandCards[i];

							outcomeText = (luckyHandCardWin[i] != 0) ? getTranslationByName("luckyMatchInHand", translations) + ' ' + (luckyHandCardWin[i]).toString() : '';

							r.push('<tr class="tablebody">');
							r.push('<td style="padding-right:10px">' + cardText + '</td>');
							r.push('<td style="padding-right:10px">' + outcomeText + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');

						///////////////////////
						// Output Bonus Game //
						///////////////////////

						if (bonusTriggerHand != 0)
						{
							r.push('<p>' + getTranslationByName("bonusGame", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr class="tablehead">');
							r.push('<td style="padding-right:10px">' + getTranslationByName("bonusCard", translations) + '</td>');

							for (var i=0; i<12; i++)
							{
								r.push('<td style="padding-right:10px">' + (i+1).toString() + '</td>');
							}

							r.push('</tr>');
							r.push('<tr class="tablebody">');
							r.push('<td style="padding-right:10px">' + getTranslationByName("bonusRank", translations) + '</td>');

							for (var i=0; i<12; i++)
							{
								cardNum = parseInt(bonusCard[i]);
								rankNum = (cardNum - 1) % 13;

								r.push('<td style="padding-right:10px">' + rankText[rankNum] + '</td>');
							}

							r.push('</tr>');
							r.push('<tr class="tablebody">');
							r.push('<td style="padding-right:10px">' + getTranslationByName("bonusSuit", translations) + '</td>');

							var bonusSuitCount = 0;

							for (var i=0; i<12; i++)
							{
								cardNum = parseInt(bonusCard[i]);
								suitNum = (cardNum <= 13) ? getTranslationByName("bonusLuckySuit", translations) : '';

								bonusSuitCount += (cardNum <= 13) ? 1 : 0;

								r.push('<td style="padding-right:10px">' + suitNum + '</td>');
							}

							r.push('</tr>');
							r.push('</table>');

							prizeText = 'B' + (bonusSuitCount).toString();

							r.push('<p>' + getTranslationByName("bonusCount", translations) + ' : ' + (bonusSuitCount).toString() + '</p>');
							r.push('<p>' + getTranslationByName("bonusPrize", translations) + ' : ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)] + '</p>');
						}

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					function getPlayerHands(scenario)
					{
						var allData = scenario.split("|");
						var playerHands = [];

						for (var i=0; i<6; i++)
						{
							playerHands.push(allData[i].split(","));
						}

						return playerHands; 
					}

					function getLuckyHand(scenario)
					{
						var luckyHandData = scenario.split("|")[6];

						return luckyHandData.split(",");
					}

					function getBonusTriggerHand(scenario)
					{
						return parseInt(scenario.split("|")[7]);
					}

					function getBonusCards(scenario)
					{
						var bonusCardData = scenario.split("|")[8];

						return bonusCardData.split(",");
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
