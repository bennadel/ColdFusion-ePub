
<!--- 
	Import the ePub name-space for creating our ePub format digital
	book in ColdFusion. This is essentially a collection of XHTML 
	files and configuration data. This project will abstract this
	level of detail. 
---> 
<cfimport prefix="epub" taglib="../../library/epub/" />


<!---
	We are going to use ColdFusion custom tags to define the 
	elements of the book. These are just an abstraction layer above 
	the underlying component layer.
	
	NOTE: We are supplying a tempDirectory value for "scratch" 
	space. If we excluded it, the ePub library would be using the
	getTempDirectory() value instead.
--->
<epub:book
	title="Movies Worth Watching"
	author="Ben Nadel"
	publisher="Kinky Solutions"
	filename="#expandPath( './movies.epub' )#"
	overwrite="true"
	tempdirectory="#expandPath( './temp/' )#"
	convertimagestopng="true">
	
	
	<!--- This is an optional stylesheet override. --->
	<epub:stylesheet>
	
		body {
			font-family: "helvetic nueue" ;
			}
			
		body.titlePage h1,
		body.titlePage h2 {
			text-align: center ;
			}
			
		p {
			margin: 0px 0px 0px 0px ;
			text-indent: 0.3in ;
			}
			
		p.moviePoster {
			margin: 0px 0px 20px 0px ;
			text-align: center ;
			}
			
		p.moviePoster img {
			border: 10px solid #CCCCCC ;
			}

	</epub:stylesheet>
	
	
	<epub:section class="titlePage">
	
		<h1>
			Movies Worth Watching
		</h1>
		
		<h2>
			by Ben Nadel
		</h2>
		
	</epub:section>
	
	
	<epub:section>
	
		<h1>
			Preface
		</h1>
		
		<p>
			I've always loved movies. For as long as I can remember,
			movie watching has been a hugely rewarding part of my
			life. I find that almost all movies have something in
			them that is rewarding, from slap-stick comedies, to 
			coming of age dramas, to documentaries.  
		</p>
		
		<p>
			In this book, I'd like to sift through them all and 
			present you with the cream of the crop - the movies
			are defintely worth watching.
		</p>
	
	</epub:section>
	
	
	<epub:section>
	
		<h1>
			Terminator 2
		</h1>
		
		<p class="moviePoster">
			<img 
				src="./images/terminator_2.jpg"
				width="213" 
				height="300" 
				/>
		</p>
		
		<p>
			This has to be one of the best movies of all time. It is
			one of the few sequels that has surpased the original by
			leaps and bounds. While T1 was a great movie, T2 is just
			in a different league. 
		</p>
	
	</epub:section>
	
	
	<epub:section>
	
		<h1>
			When Harry Met Sally
		</h1>
		
		<p class="moviePoster">
			<img 
				src="images/when_harry_met_sally.jpg"
				width="203" 
				height="300" 
				/>
		</p>
		
		<p>
			Perhaps one of the greatest romantic comedies ever made,
			this movie..... 
		</p>
	
	</epub:section>
	
	
</epub:book>


<!--- ----------------------------------------------------- --->
<!--- ----------------------------------------------------- --->
<!--- ----------------------------------------------------- --->
<!--- ----------------------------------------------------- --->


<h1>
	Your ePub Book Has Been Generated!
</h1>

<p>
	Your ePub file awaits: <a href="./movies.epub">movies.epub</a>.
</p>

