package nl.nnbp.gamesapp.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import nl.nnbp.gamesapp.ui.theme.*

data class DisputeFaqItem(
    val gameName: String,
    val question: String,
    val verdict: String, // "❌ VERBODEN", "✅ TOEGESTAAN", "⚖️ REGEL"
    val answer: String,
    val isVerdictAllowed: Boolean? = null // true = green, false = red, null = blue
)

val AllDisputeFaqs: List<DisputeFaqItem> = listOf(
    // 30 Seconds
    DisputeFaqItem(
        gameName = "30 Seconds",
        question = "Mag je rijmen of 'klinkt als...' gebruiken?",
        verdict = "❌ STRIKT VERBODEN",
        answer = "Nee, volgens de officiële regels is rijmen, 'klinkt als...' of 'begint met...' absoluut verboden.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "30 Seconds",
        question = "Mag je woorden vertalen naar Engels of een andere taal?",
        verdict = "❌ VERBODEN",
        answer = "Nee, vertalingen zijn niet toegestaan. Je mag het begrip alleen omschrijven in de afgesproken speeltaal (meestal Nederlands).",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "30 Seconds",
        question = "Mag je letters spellen of de beginletter noemen?",
        verdict = "❌ VERBODEN",
        answer = "Nee, je mag noch de letters spellen noch de beginletter verklappen.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "30 Seconds",
        question = "Mag je wijzen naar objecten of kleding in de kamer?",
        verdict = "❌ VERBODEN",
        answer = "Nee, wijzen naar tastbare voorwerpen of personen in de ruimte is niet toegestaan.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "30 Seconds",
        question = "Mag je neuriën of melodietjes zingen?",
        verdict = "❌ VERBODEN",
        answer = "Nee, neuriën of fluiten van melodieën is niet toegestaan tenzij het een zangregel betreft.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "30 Seconds",
        question = "Mag je een deel van een samengestelde naam noemen?",
        verdict = "❌ VERBODEN",
        answer = "Nee, geen enkel deel van de naam (bijvoorbeeld 'Barack' als het 'Barack Obama' is) mag worden uitgesproken.",
        isVerdictAllowed = false
    ),

    // Cranium
    DisputeFaqItem(
        gameName = "Cranium",
        question = "Mag je praten of geluidseffecten maken bij Uitbeelden?",
        verdict = "❌ GEEN GELUID",
        answer = "Nee, bij Typetje/Uitbeelden mag de speler geen enkel geluid maken of lippen bewegen.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "Cranium",
        question = "Mag je letters of cijfers boetseren met de klei?",
        verdict = "❌ VERBODEN",
        answer = "Letters, cijfers en leestekens zijn strikt verboden bij zowel Kleien als Tekenen.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "Cranium",
        question = "Wat als niemand het antwoord weet bij Club Cranium?",
        verdict = "⚖️ BEURT VOORBIJ",
        answer = "Als geen enkel team binnen de tijd het antwoord raadt, eindigt de beurt zonder vooruitgang en is het volgende team aan de beurt.",
        isVerdictAllowed = null
    ),

    // Balzakken
    DisputeFaqItem(
        gameName = "Balzakken",
        question = "Twee spelers roepen tegelijk 'Balzak!', wie krijgt hem?",
        verdict = "⚖️ EERSTE HOORBARE STEM",
        answer = "De speler die als eerste hoorbaar 'Balzak!' riep krijgt de beurt. Bij absolute twijfel telt de speler die de kaart aflegde of op dat moment aan de beurt was.",
        isVerdictAllowed = null
    ),
    DisputeFaqItem(
        gameName = "Balzakken",
        question = "Wat gebeurt er als je 'Balzak' roept maar de optelsom klopt niet?",
        verdict = "⚠️ VALSE BALZAK (+25 PT)",
        answer = "Dat is een Valse Balzak! De roeper ontvangt direct 25 strafpunten.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "Balzakken",
        question = "Mag je wachten met roepen tot de volgende speler pakt?",
        verdict = "❌ TE LAAT!",
        answer = "Zodra de volgende speler een kaart raakt of aflegt, is het moment voor de vorige ronde definitief voorbij.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "Balzakken",
        question = "Wat gebeurt er bij exact 69 of 99 punten?",
        verdict = "✅ HERSTELREGEL",
        answer = "Eindig je precies op 69 punten, dan daalt je score naar 0! Eindig je precies op 99 punten, dan zakt je score naar 50.",
        isVerdictAllowed = true
    ),

    // Beverbende
    DisputeFaqItem(
        gameName = "Beverbende",
        question = "Mag je tussendoor nog even naar je eigen kaarten spieken?",
        verdict = "❌ VERBODEN",
        answer = "Nee! Je mag je eigen kaarten alleen bekijken als een actiekaart (zoals de Spiek-kaart / Verkenner) dit toestaat.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "Beverbende",
        question = "Mag je de positie van je 4 kaarten verwisselen?",
        verdict = "❌ POSITIE IS VAST",
        answer = "De 4 posities (links naar rechts) moeten te allen tijde vast op tafel blijven liggen.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "Beverbende",
        question = "Wat als degene die 'Laatste ronde' riep toch niet wint?",
        verdict = "⚠️ STRAFKAART",
        answer = "Als de speler die de laatste ronde aankondigde niet de strikt laagste score heeft, krijgt diegene de hoogste kaart van de trekstapel als extra strafkaart!",
        isVerdictAllowed = false
    ),

    // Duizenden
    DisputeFaqItem(
        gameName = "Duizenden",
        question = "Moet je altijd kleur bekennen?",
        verdict = "✅ ALTIJD BEKENNEN",
        answer = "Ja, je bent te allen tijde verplicht de gevraagde kleur te bekennen als je die in de hand hebt.",
        isVerdictAllowed = true
    ),
    DisputeFaqItem(
        gameName = "Duizenden",
        question = "Wanneer mag je voor het eerst tafelpunten neerleggen?",
        verdict = "⚖️ MINIMAAL 40 PUNTEN",
        answer = "Je mag pas kaarten op tafel uitleggen als je in één beurt minstens 40 (of volgens huisregel 50) punten tegelijk op tafel legt.",
        isVerdictAllowed = null
    ),
    DisputeFaqItem(
        gameName = "Duizenden",
        question = "Hoeveel strafpunten is Harten Vrouw in je hand bij het uitgaan?",
        verdict = "⚠️ 100 STRAFPUNTEN",
        answer = "De Harten Vrouw in je hand als iemand anders uitspeelt levert 100 strafpunten op! Azen zijn 20 minpunten, plaatjes 10 minpunten.",
        isVerdictAllowed = false
    ),

    // Regenwormen
    DisputeFaqItem(
        gameName = "Regenwormen",
        question = "Mag je een tegel stelen die midden in iemands stapel zit?",
        verdict = "❌ ALLEEN BOVENSTE TEGEL",
        answer = "Je mag alleen de direct zichtbare bovenste tegel van iemands stapel stelen, mits de totale worpwaarde exact gelijk is.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "Regenwormen",
        question = "Wat als ik een geldige som heb gegooid maar géén enkele wormsteen bezit?",
        verdict = "❌ WORP MISLUKT",
        answer = "Om een tegel te pakken móét je minimaal 1 dobbelsteen met een worm hebben gekozen. Heb je geen wormen, dan is je beurt direct mislukt!",
        isVerdictAllowed = false
    ),

    // Qwixx
    DisputeFaqItem(
        gameName = "Qwixx",
        question = "Mag je een getal links van een bestaand kruisje alsnog aankruisen?",
        verdict = "❌ NOOIT TERUG NAAR LINKS",
        answer = "Nee, in Qwixx mag je uitsluitend van links naar rechts kruisen. Overgeslagen getallen zijn voor altijd verloren.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "Qwixx",
        question = "Wanneer mag je het laatste getal (12 of 2) en het slotje aankruisen?",
        verdict = "⚖️ MINSTENS 5 KRUISJES",
        answer = "Je mag het laatste vakje pas aankruisen als je al minstens 5 eerdere getallen in diezelfde kleurrij hebt aangekruist.",
        isVerdictAllowed = null
    ),

    // Ticket to Ride
    DisputeFaqItem(
        gameName = "Ticket to Ride",
        question = "Mag je beide sporen van een dubbelspoor gebruiken bij 2 of 3 spelers?",
        verdict = "❌ SLECHTS 1 SPOOR BESCHIKBAAR",
        answer = "Bij 2 of 3 spelers is per dubbelspoor slechts 1 spoor beschikbaar. Zodra één speler het spoor bouwt, is het andere spoor voor de rest van het spel geblokkeerd.",
        isVerdictAllowed = false
    ),
    DisputeFaqItem(
        gameName = "Ticket to Ride",
        question = "Mag je twee routes tegelijk leggen in één beurt?",
        verdict = "❌ MAXIMAAL 1 ROUTE PER BEURT",
        answer = "Je mag per beurt maximaal 1 route claimen, of treinkaarten pakken, of bestemmingskaarten trekken.",
        isVerdictAllowed = false
    ),

    // Love Letter
    DisputeFaqItem(
        gameName = "Love Letter",
        question = "Moet je de Gravin (7) spelen als je de Prins (5) of Koning (6) hebt?",
        verdict = "✅ JA, VERPLICHT AFLEGGEN",
        answer = "Ja! Als je de Gravin hebt in combinatie met de Prins of Koning, ben je reglementair verplicht de Gravin direct te spelen.",
        isVerdictAllowed = true
    ),
    DisputeFaqItem(
        gameName = "Love Letter",
        question = "Mag je met de Wachter (1) raden op een andere Wachter?",
        verdict = "❌ VERBODEN",
        answer = "Nee, je mag elke rol van 2 t/m 8 noemen, maar nóóit Wachter zelf.",
        isVerdictAllowed = false
    ),

    // Pig Hole
    DisputeFaqItem(
        gameName = "Pig Hole",
        question = "Wat gebeurt er als je 6 gooit?",
        verdict = "✅ HET GAT IN!",
        answer = "Het varkentje valt door het gat in het midden en verlaat voor altijd het speelbord.",
        isVerdictAllowed = true
    ),
    DisputeFaqItem(
        gameName = "Pig Hole",
        question = "Wat gebeurt er als je gooit op een bezet holletje (1 t/m 5)?",
        verdict = "⚠️ ALLE VARKENS OPPPAKKEN",
        answer = "Je moet alle varkens die op dat moment op het speelbord staan aan je voorraad toevoegen en je beurt is direct voorbij!",
        isVerdictAllowed = false
    )
)

@Composable
fun WieHeeftGelijkDialog(
    initialGameFilter: String? = null,
    onDismiss: () -> Unit
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedGame by remember { mutableStateOf(initialGameFilter ?: "Alle") }
    var expandedItemIndex by remember { mutableStateOf<Int?>(null) }

    val distinctGames = remember {
        listOf("Alle") + AllDisputeFaqs.map { it.gameName }.distinct()
    }

    val filteredList = remember(searchQuery, selectedGame) {
        AllDisputeFaqs.filter { item ->
            val matchesGame = selectedGame == "Alle" || item.gameName.equals(selectedGame, ignoreCase = true)
            val matchesSearch = searchQuery.isBlank() ||
                    item.question.contains(searchQuery, ignoreCase = true) ||
                    item.answer.contains(searchQuery, ignoreCase = true) ||
                    item.gameName.contains(searchQuery, ignoreCase = true) ||
                    item.verdict.contains(searchQuery, ignoreCase = true)
            matchesGame && matchesSearch
        }
    }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = SurfaceDark)
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .fillMaxWidth()
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(PrimaryBlue.copy(alpha = 0.2f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("⚖️", fontSize = 18.sp)
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = "Wie heeft gelijk?",
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            Text(
                                text = "Bordspel Scheidsrechter & FAQ",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.White.copy(alpha = 0.6f)
                            )
                        }
                    }
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Sluiten", tint = Color.White)
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Zoekbalk
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Zoek regel of twistpunt...") },
                    leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    singleLine = true,
                    shape = RoundedCornerShape(14.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedContainerColor = CardBackground,
                        unfocusedContainerColor = CardBackground,
                        focusedBorderColor = PrimaryBlue,
                        unfocusedBorderColor = Color.White.copy(alpha = 0.15f)
                    )
                )

                Spacer(modifier = Modifier.height(10.dp))

                // Game filter chips
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    distinctGames.forEach { g ->
                        val isSel = g == selectedGame
                        FilterChip(
                            selected = isSel,
                            onClick = { selectedGame = g },
                            label = { Text(g, fontSize = 12.sp) },
                            shape = RoundedCornerShape(12.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Vragenlijst
                if (filteredList.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(180.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("🤷‍♂️", fontSize = 32.sp)
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                "Geen regels gevonden voor \"$searchQuery\"",
                                color = Color.White.copy(alpha = 0.6f),
                                fontSize = 13.sp
                            )
                        }
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f, fill = false)
                            .heightIn(max = 380.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        items(filteredList) { item ->
                            val index = AllDisputeFaqs.indexOf(item)
                            val isExpanded = expandedItemIndex == index

                            val verdictColor = when (item.isVerdictAllowed) {
                                true -> SuccessGreen
                                false -> WarningRed
                                null -> PrimaryBlue
                            }

                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        expandedItemIndex = if (isExpanded) null else index
                                    },
                                shape = RoundedCornerShape(14.dp),
                                colors = CardDefaults.cardColors(containerColor = CardBackground),
                                border = if (isExpanded) androidx.compose.foundation.BorderStroke(1.dp, verdictColor.copy(alpha = 0.6f)) else null
                            ) {
                                Column(modifier = Modifier.padding(14.dp)) {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Surface(
                                            color = verdictColor.copy(alpha = 0.18f),
                                            shape = RoundedCornerShape(6.dp)
                                        ) {
                                            Text(
                                                text = item.verdict,
                                                color = verdictColor,
                                                fontSize = 10.sp,
                                                fontWeight = FontWeight.Bold,
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                            )
                                        }

                                        Text(
                                            text = item.gameName,
                                            fontSize = 11.sp,
                                            color = Color.White.copy(alpha = 0.5f),
                                            fontWeight = FontWeight.Medium
                                        )
                                    }

                                    Spacer(modifier = Modifier.height(8.dp))

                                    Text(
                                        text = item.question,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White,
                                        fontSize = 14.sp
                                    )

                                    AnimatedVisibility(visible = isExpanded) {
                                        Column(modifier = Modifier.padding(top = 10.dp)) {
                                            HorizontalDivider(color = Color.White.copy(alpha = 0.08f))
                                            Spacer(modifier = Modifier.height(8.dp))
                                            Text(
                                                text = item.answer,
                                                fontSize = 13.sp,
                                                color = Color.White.copy(alpha = 0.85f),
                                                lineHeight = 18.sp
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
