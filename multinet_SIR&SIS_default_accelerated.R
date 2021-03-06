# biblioteka 
library(multinet)
listMultiply<- c(1,2,3,4)
listBeta <- c(0.19,0.28,0.22,0.31)
listgamma <- c(0.1,0.08,0.02,0.1)
networkName <- "MoscowAthletics2013"

scritpType<-"SIS&SIR_default"
networkFileName <-"MoscowAthletics2013_4NoNatureNoLoops.edges"
network<-read_ml(paste("C:/Users/Paulina/Downloads/FullNet/",networkFileName,sep=""), name=networkName, sep=',', aligned=FALSE)

layerName <- "RE"
for( w in 1: length(listMultiply))
{
  countryDirectory <- paste("MultiplyBy", listMultiply[w], sep="")
for(value in 1:length(listBeta))
{
  if (value == 1){
        # Parametry zapisu eksperymentu  -------------------------------------------------
    # Folder roboczy
    setwd("C:/Users/Paulina/Documents/MasterThesis/Eksperiments/")
    getwd()
    #zmienne pomocniecze do zapisu
    experimentsMainDirectory<- paste("SIR&SIS",networkName, sep="-")
    if(dir.exists(experimentsMainDirectory) == FALSE) dir.create(experimentsMainDirectory)
    #folder dla eksperyment�w 
    setwd(paste("C:/Users/Paulina/Documents/MasterThesis/Eksperiments/", experimentsMainDirectory, sep=""))
    if(dir.exists(countryDirectory) == FALSE) dir.create(countryDirectory)
    setwd(paste(getwd(), countryDirectory,sep="/"))
  }
  setwd(paste(paste("C:/Users/Paulina/Documents/MasterThesis/Eksperiments/",experimentsMainDirectory,sep=""),countryDirectory,sep="/"))  
  mainDirectory <-paste(listBeta[value],listgamma[value], sep = "-")
  if(dir.exists(mainDirectory) == FALSE) dir.create(mainDirectory)
  setwd(paste(getwd(),mainDirectory, sep="/") )
  if(dir.exists(scritpType) == FALSE) dir.create(scritpType)
  setwd(paste(getwd(),scritpType, sep="/") )
  getwd()

experimentsNumber <- 20 

for(e in 1:experimentsNumber)
{	
    net <- network
	
	#parametry sieci
	numberOfActors <- num_actors_ml(net)
	numberOfActorsInLayer <- num_actors_ml(net,layerName)
	layerActors <- actors_ml(net,layerName)
	networkActors <- actors_ml(net)

	# definicje zmiennych dla modeli
	#czas trwania "epidemii" -  liczba dni
	time <- 150

	# prawdopodobie�stwa SIR
	beta <- listBeta[value] # zara�enia
	betaI <- beta /10 #je�li SIS w stanie I  
	gamma <- listgamma[value] # wyzdrowienia
	
	# prawdopodobie�stwa SIS
	epsilon <- beta * listMultiply[w] # odpowiednik beta, uzuskania informacji
	epsilonI <- 0.692 # je�li SIR w stanie I Japan  0.692 lub DiamonPrincess 0.821 
	mi <- gamma * listMultiply[w]    # zwatpienia
	
	blockingTime <- 21

	#Stan SIR
	numberOfSusceptible <- numberOfActorsInLayer
	numberOfInfected  <- 0 #
	numberOfRecovered <- 0 # ozdrowie�cy
	SIR_Sum <- numberOfSusceptible + numberOfInfected + numberOfRecovered 

	#Stan SIS
	numberOfUnawarened <-numberOfActors
	numberOfAwarened <- 0
	SIS_Sum <- numberOfAwarened + numberOfUnawarened
	 
	 # Stan pocz�tkowy dla macierzy liczno�ci
	SIR_group_States <- matrix(rbind(0,numberOfSusceptible, numberOfInfected, numberOfRecovered, SIR_Sum))
	SIS_group_States <- matrix (rbind(0, numberOfUnawarened, numberOfAwarened, SIS_Sum))

	# zmienne pomocnicze
	new_infected <- NULL # nowe zachorowania
	new_recovered <- NULL # nowe ozdrowienia

	new_awarened <- NULL # �wiadomi S
	new_unawarened <- NULL # nie�wiadomi versus wypieraj�cy
 
	attributeState <- vector(mode="character", numberOfActorsInLayer)
    attributeState [1:numberOfActorsInLayer] <- "S"
	
	attributeBeta <- vector(mode ="numeric", numberOfActorsInLayer)
	attributeBeta [1:numberOfActorsInLayer]<- beta 
	
	attributeAwareness <- vector(mode="character", numberOfActors)
	attributeAwareness [1:numberOfActors] <- "S"
	
	attributeEpsilon <- vector(mode="character", numberOfActors)
	attributeEpsilon [1:numberOfActors] <- epsilon


	# stan pocz�tkowy dla I ---------------------------------------------------
	# (A)losowo X os�b 
	# x<-5 
	# infected <- trunc(runif(x,1,215))
	# while (n>0)
	# { (print (infected[n]))
	#   set_values_ml(net, "state",infected[n], values ="I" )
	#  print(get_values_ml(net, "state",infected[n]))
	#  n=n-1
	# }

	# (B)losowo x % sieci - preferowane np 1% - liczymi ile to aktor�w w sieci a potem losujemy tylu aktor�w jako seedy
	x<-0.01
	n<- round( x * num_actors_ml(net,layerName)) # dla warstwy x % aktor�w z wybranej warstwy
	infected <- trunc(runif(n,1,numberOfActorsInLayer))

	# Aktualizowanie stanu SIR
	numberOfInfected <- n
	numberOfSusceptible <- numberOfSusceptible - numberOfInfected

	# zainfekowanie wylosowanych aktor�w
	while (n>0)
	{ print( paste("infekowanie w toku - aktor :", infected[n]))
	  #set_values_ml(net, "state",layerActors[infected[n]], values ="I" )
	  attributeState[infected[n]]= "I"
	  n=n-1
	}

	#u�wiadomienie wybranych os�b 
	x <- 0.01
	m <- round( x * num_actors_ml(net)) # x % aktor�w z ca�ej sieci
	awarened <- trunc(runif(m,1,numberOfActorsInLayer))

	# Aktualizowanie stanu SIS
	numberOfAwarened <- m
	numberOfUnawarened <- numberOfUnawarened - numberOfAwarened

	while (m>0)
	{ print( paste("u�wiadamianie w toku - aktor :", awarened[m]))
	  attributeAwareness[awarened[m]] = "I"
	  m=m-1
	  
	}

	timeline_SIR <- as.matrix(layerActors)
	timeline_SIR <- cbind(timeline_SIR, attributeState)
	timeline_SIS <- as.matrix(networkActors)
	timeline_SIS <- cbind(timeline_SIS, attributeAwareness)

	for(i in 1:time ) # odliczamy kolejne dni 1 iteracja - 1 dzie�
	{ # print(attributeState)
	  # wypisuje - Stan SIR na konsole 
	  SIR_group_States <- cbind(SIR_group_States,rbind(i,numberOfSusceptible,numberOfInfected,numberOfRecovered, SIR_Sum))
	  print(paste("Dzie� epidemii:", i)) 
	  print(paste("Stan SIR:", paste( paste( paste("Susceptible:", numberOfSusceptible),paste("Infected:", numberOfInfected), sep = " ; "),paste("Recovered:", numberOfRecovered),sep =" ; ")))
	  
	  if(numberOfRecovered == numberOfActorsInLayer) break 
	  if(numberOfInfected == 0) break 
	  
	  new_infected <- NULL
	  new_recovered <- NULL
	  
	  #tablica stan�w w sieci  SIR
	  actualInfectedInLayer <-  which(attributeState == "I")
	  if(length(actualInfectedInLayer) != 0)
	  
	  # P�tla SIR
	  for (j in 1:length(actualInfectedInLayer)) # odwiedzam po kolei aktor�w
	  { 
		#if(get_values_ml(net,"state",layerActors[actualInfectedInLayer[j]]) =="I") # je�li aktor jest zara�ony
		#{ 
		  # szukamy s�siad�w 
		  neighbors <- neighbors_ml(net,layerActors[actualInfectedInLayer[j]],layerName,mode="all")
		  if(length(neighbors)!= 0)
		  for(s in 1:length(neighbors))
		  		  { neighborIndex <- which(layerActors == neighbors[s])
		  if( attributeState[neighborIndex]=="S")# sprawdzamy indeks aktora 
				{ 
				if(attributeAwareness[which(networkActors == neighbors[s])] == "I") # szukamy aktora w du�ej sieci
					{ 
				  attributeBeta[which(layerActors == neighbors[s])] = betaI 
					#set_values_ml(net, "beta",neighbors[s], values = betaI)
					}
					
					if(runif(1) < attributeBeta[neighborIndex] )#get_values_ml(net, "beta", neighbors[s])) 
					{ #print( value)
					if(!(neighborIndex %in% new_infected)) # is.element(neighbors[s])
						new_infected <- cbind(new_infected,neighborIndex) # mamy tymczasow� list� nowo zainfekowanych  							
					}
				}
			}
		  
		  if( runif(1) < gamma)
		  { #print(test)
			if(!is.element(actualInfectedInLayer[j],new_recovered))
			{
			new_recovered=cbind(new_recovered,actualInfectedInLayer[j])
			}
		  }
		#}
		
	  }
	  
	  print( paste("Stan SIS:", paste( paste( paste("Susceptible:", numberOfUnawarened),paste("Infected:", numberOfAwarened), sep = " ; "))))
	  SIS_group_States <- cbind(SIS_group_States,rbind(i,numberOfUnawarened,numberOfAwarened, SIS_Sum))
	  
	  new_awarened <- NULL # �wiadomi S
	  new_unawarened <- NULL # nie�wiadomi versus wypieraj�cy
	  
	  #tablica stan�w w sieci SIS
	  actualInfectedInNetwork <- which(attributeAwareness == "I") 
	    if(length(actualInfectedInNetwork) != 0)
	  #if(i>blockingTime)
		  #P�tla dla SIS
		  for(k in 1: length(actualInfectedInNetwork)) #odwiedzam aktor�w po kolei 
		  {
			#if(get_values_ml(net,"state",networkActors[a # odwiedzam po kolei aktor�wctualInfectedInNetwork[k]]) == "I")
			#{ 
			  # poszukiwanie s�siad�w
			  actorNeighbors <- neighbors_ml(net,networkActors[actualInfectedInNetwork[k]],layerName,mode="all")
			  if(length(actorNeighbors)!= 0)
			  for(l in 1:length(actorNeighbors))
			  {  actorIndex <- which(networkActors == actorNeighbors[l])
				if( attributeAwareness[actorIndex]=="S")
								{  if(attributeState[which(layerActors == neighbors[s])] == "I")
					{	 attributeEpsilon[which(networkActors == neighbors[s])]=epsilonI
						#set_values_ml(net, "epsilon",actorNeighbors[l], values = epsilonI)
					}
					 
					if( runif(1) < attributeEpsilon[actorIndex])
					{ #print( value)
						if(!(actorIndex %in% new_awarened)) # is.element(neighbors[s])
						new_awarened <- cbind(new_awarened,actorIndex) # mamy tymczasow� list� nowo zainfekowanych  							
					}
				}		   
			  }
			  if( runif(1) < mi)
			  { #print(test)
				if(!is.element(actualInfectedInNetwork[k],new_unawarened)){ new_unawarened=cbind(new_unawarened,actualInfectedInNetwork[k])}
				
			  }
			#}
			
		  }
	  
	  
	  
	  # aktualizacja nowych zaka�e� i ozdrowienia je�li si� pojawi�y
	  if(!is.null(new_infected))  
	    for( q in 1: length(new_infected)){attributeState[new_infected[q]]= "I"}
	    #set_values_ml(net, "state",new_infected, values ="I" )
	  if(!is.null(new_recovered))   for( r in 1: length(new_recovered)){attributeState[new_recovered[r]]= "R"}
	    #set_values_ml(net, "state",new_recovered, values ="R" )
	  	  
	  #aktualizacja SIS    
	  if(!is.null(new_awarened))  for( a in 1:length(new_awarened)) {attributeAwareness[a] = "I"} #set_values_ml(net, "awareness",new_awarened, values ="I" )
	  if(!is.null(new_unawarened)) for( u in 1:length(new_unawarened)) {attributeAwareness[u] = "S"} # set_values_ml(net, "awareness",new_unawarened, values ="S" )
	  
	   # Sprawdzenie stanu atrybut�w - zawarto�� wektora 
	  #SIR_attributes <- get_values_ml(net,"state", layerActors)
	  numberOfSusceptible <- length( which('S' == attributeState))
	  numberOfInfected <- length( which('I' == attributeState))
	  numberOfRecovered <- length( which('R' == attributeState))
	  Sum = numberOfSusceptible + numberOfInfected + numberOfRecovered
	  
	  #SIS_atributes <- get_values_ml(net, "awareness", networkActors)  
	  numberOfUnawarened <- length(which("S"==attributeAwareness))
	  numberOfAwarened <- length(which("I"== attributeAwareness))
	  SIS_Sum <- numberOfAwarened + numberOfUnawarened 
	  
	  # zapis stan�w po�rednich 
	  timeline_SIR <- cbind(timeline_SIR,attributeState)
	  timeline_SIS <- cbind(timeline_SIS, attributeAwareness)
	}
	SIR_group_States <- t(SIR_group_States)
	SIS_group_States <- t(SIS_group_States)
	#get_values_ml(net,"beta",actors_ml(net))
	#get_values_ml(net,"epsilon",actors_ml(net))


	# zapis wynik�w z e-tej iteracji  -----------------------------------------
	experimentDescription <- paste("eksperymentData",e, sep="-")
	
	# zapis do pliku dat.
	write.table(SIR_group_States,file=paste("Summary_SIR",(paste(e,".dat", sep = "")), sep="-"), col.names =TRUE, sep =";", row.names = TRUE )
	write.table(timeline_SIR,file=paste("timelineStates_SIR",(paste(e,".dat", sep = "")), sep="-"), col.names =TRUE, sep =";", row.names = TRUE )
	
	# zapis do pliku dat.
	write.table(SIS_group_States,file=paste("Summary_SIS",(paste(e,".dat", sep = "")), sep="-"), col.names =TRUE, sep =";", row.names = TRUE )
	write.table(timeline_SIS,file=paste("timelineStates_SIS",(paste(e,".dat", sep = "")), sep="-"), col.names =TRUE, sep =";", row.names = TRUE )
	
	# zapis RData
	save(list = ls(all.names = TRUE), file =paste( experimentDescription,".RData",sep=""), envir = .GlobalEnv)
}
}
}