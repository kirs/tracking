module ScoreHelper

#========================= Fleet Race  =============================
    def checkLineCrossed(myLine,coordinates)
      # résolution paramétrique
      # caracteristiques de la ligne
      line = myLine
      l1 = [line[0][0].to_f,line[1][0].to_f] # extrémité 1 A => l1[0] : Ax, l1[1] : Ay
      l2 = [line[0][1].to_f,line[1][1].to_f] # extrémité 2 B
      vl = [l2[0]-l1[0],l2[1]-l1[1]] # vecteur l1l2 I => vl[0] : Ix, vl[1] : Iy

      #iterer les coordonnées pour savoir si on passe la ligne

      c1 = [0.0,0.0]
      c2 = [0.0,0.0]
      vc = [0.0,0.0]

      time = 0

      intersec = false;
      i = 0
      while (i < coordinates.length-1)&&(!intersec)
        c1 = [coordinates[i].longitude.to_f,coordinates[i].latitude.to_f] # C => c1[0] : Cx, c1[1] : Cy
        c2 = [coordinates[i+1].longitude.to_f,coordinates[i+1].latitude.to_f] #D
        vc = [c2[0]-c1[0],c2[1]-c1[1]] # J  => vc[0] : Jx, vc[1] : Jy


        cond1 = vl[0]*vc[1]-vl[1]*vc[0] # condition de non parallélisme : si = 0 => segments parallèles
        if (cond1 != 0)
          m = ( -vl[0]*c1[1]+vl[0]*l1[1] - vl[1]*l1[0]+vl[1]*c1[0] )/cond1;
          k = ( -vc[0]*c1[1]+vc[0]*l1[1] - vc[1]*l1[0]+vc[1]*c1[0] )/cond1;
          if ((m<=1)&&(m>=0)&&(k<=1)&&(k>=0))
            intersec=true
            time = coordinates[i+1].datetime.to_f
          end
        end
        i = i + 1
      end

      return time

    end

    def checkRoundBuoy(myLine,buoy,coordinates,order)
      # 4 sectors around the buoy limited by lines, if the boat crossed all of them in a logic order it is validated

      line = myLine
      lineV = [line[0][1].to_f-line[0][0].to_f,line[1][1].to_f-line[1][0].to_f]
      pointN = [buoy[0].to_f+lineV[0],buoy[1].to_f+lineV[1]]
      pointS = [buoy[0].to_f-lineV[0],buoy[1].to_f-lineV[1]]
      pointW = [buoy[0].to_f-lineV[1],buoy[1].to_f+lineV[0]]
      pointE = [buoy[0].to_f+lineV[1],buoy[1].to_f-lineV[0]]
      lineN = [[buoy[0].to_f,pointN[0]],[buoy[1].to_f,pointN[1]]]
      lineS = [[buoy[0].to_f,pointS[0]],[buoy[1].to_f,pointS[1]]]
      lineW = [[buoy[0].to_f,pointW[0]],[buoy[1].to_f,pointW[1]]]
      lineE = [[buoy[0].to_f,pointE[0]],[buoy[1].to_f,pointE[1]]]

      time = 0

      tN = 0
      tS = 0
      tW = 0
      tE = 0

      if (order.include? "N")
        tN = checkLineCrossed(lineN,coordinates)
      end
      if (order.include? "S")
        tS = checkLineCrossed(lineS,coordinates)
      end
      if (order.include? "W")
        tW = checkLineCrossed(lineW,coordinates)
      end
      if (order.include? "E")
        tE = checkLineCrossed(lineE,coordinates)
      end

      #if (((tN != 0)||(!order.include? "N"))&&((tE != 0)||(!order.include? "E"))&&((tW != 0)||(!order.include? "W"))&&((tS != 0)||(!order.include? "S"))) 
      time = [tN,tS,tW,tE].max
      #end

      return time

    end

    def getTimeTriangularCourse(attempt)
      mission_id = attempt.mission_id
      myTrackerID= attempt.tracker_id
      startTime = attempt.start.strftime('%Y%m%d%H%M%S')
      endTime = attempt.end.strftime('%Y%m%d%H%M%S')
      coordinates = (Coordinate.where(id: Coordinate.where("datetime > ?", startTime).where("datetime < ?", endTime).where(tracker_id: myTrackerID).order(datetime: :asc))).where("datetime > ?", startTime).where("datetime < ?", endTime).where(tracker_id: myTrackerID).select(:datetime,:latitude,:longitude).order(datetime: :asc)
      
      # The markers should be created in this order : first => start line, second =>  end line, third => first buoy, fourth => second buoy
      sLine = Marker.find(1)
      eLine = Marker.find(2)
      myFirstBuoy = Marker.find(3)
      mySecondBuoy = Marker.find(4)

     # mise en forme des lignes


      startLine = []
      startLine << sLine.longitude.split("_")
      startLine << sLine.latitude.split("_")
      endLine = []
      endLine << eLine.longitude.split("_")
      endLine << eLine.latitude.split("_")

      # fin mise en forme des lignes

      # mise en forme des buoys

      firstBuoy = []
      secondBuoy = []
      firstBuoy.push(myFirstBuoy.longitude)
      firstBuoy.push(myFirstBuoy.latitude)
      secondBuoy.push(mySecondBuoy.longitude)
      secondBuoy.push(mySecondBuoy.latitude)

      # fin mise en forme des buyos

      tSL = 0
      tEL = 0
      tSB = 0
      tFB = 0
      time = 0

      tSL = checkLineCrossed(startLine,coordinates) # time for start line

      if tSL != 0
        coordinates = coordinates.where("datetime >= ?", tSL).order(datetime: :asc)

        k = coordinates.length

        tFB = checkRoundBuoy(endLine,firstBuoy,coordinates,"NSEW")

        if tFB != 0
          coordinates = coordinates.where("datetime >= ?", tFB).order(datetime: :asc)

          tSB = checkRoundBuoy(startLine,secondBuoy,coordinates,"NSEW")

          if tSB != 0
            coordinates = coordinates.where("datetime >= ?", tSB).order(datetime: :asc)

            tEL = checkLineCrossed(endLine, coordinates)
          end
        end
      end

      if tEL != 0
        time = tEL.to_f - tSL.to_f
      end

      return time

    end

    def getTimeRaceCourse(attempt)
      mission_id = attempt.mission_id
      myTrackerID= attempt.tracker_id
      startTime = attempt.start.strftime('%Y%m%d%H%M%S')
      endTime = attempt.end.strftime('%Y%m%d%H%M%S')
      globalStartTime = Mission.find(mission_id).startOfRace
      coordinates = (Coordinate.where(id: Coordinate.where("datetime > ?", startTime).where("datetime < ?", endTime).where(tracker_id: myTrackerID).order(datetime: :asc))).where("datetime > ?", startTime).where("datetime < ?", endTime).where(tracker_id: myTrackerID).select(:datetime,:latitude,:longitude).order(datetime: :asc)

      # The markers should be created in this order : first => start line (first point of the start line = first Buoy), second => first Buoy, third => second Buoy, fourth => third Buoy, fifth => fourth Buoy

      sLine = Marker.find(1)
      firstCorner = Marker.find(2) # order
      secondCorner = Marker.find(3) # order
      thirdCorner = Marker.find(4) # order
      fourthCorner = Marker.find(5) # order

      startLine = []
      startLine << sLine.longitude.split("_")
      startLine << sLine.latitude.split("_")     
      firstBuoy = []
      secondBuoy = []
      thirdBuoy = []
      fourthBuoy = []
      firstBuoy.push(firstCorner.longitude)
      firstBuoy.push(firstCorner.latitude)
      secondBuoy.push(secondCorner.longitude)
      secondBuoy.push(secondCorner.latitude)
      thirdBuoy.push(thirdCorner.longitude)
      thirdBuoy.push(thirdCorner.latitude)
      fourthBuoy.push(fourthCorner.longitude)
      fourthBuoy.push(fourthCorner.latitude)

      time = 0
      turn = 0

      for i in 1..2
        tFiB = 0
        tSeB = 0
        tThB = 0
        tFoB = 0

        tSeB = checkRoundBuoy(startLine, secondBuoy, coordinates, "NW")
        

        if (tSeB != 0)
          coordinates = coordinates.where("datetime >= ?", tSeB).order(datetime: :asc)
          tThB = checkRoundBuoy(startLine, thirdBuoy, coordinates, "WS")
          

          if (tThB != 0)
            coordinates = coordinates.where("datetime >= ?", tThB).order(datetime: :asc)
            tFoB = checkRoundBuoy(startLine, fourthBuoy, coordinates, "SE")
            

            if (tFoB != 0)
              coordinates = coordinates.where("datetime >= ?", tFoB).order(datetime: :asc)
              tFiB = checkRoundBuoy(startLine, firstBuoy, coordinates, "EN")

              if tFiB != 0
                coordinates = coordinates.where("datetime >= ?", tFoB).order(datetime: :asc)
                turn = turn+1
                if turn == 2
                  time = timeDifference(tFiB.to_s, globalStartTime.to_s)
                end
              end
            end
          end
        end
      end
      return time
    end

    def timeDifference(t1,t2) # calculates t1-t2, both formated as %Y%m%d%H%M%S
      temp1 = DateTime.strptime(t1,'%Y%m%d%H%M%S').to_time
      temp2 = DateTime.strptime(t2,'%Y%m%d%H%M%S').to_time
      res = temp1 - temp2
      return res
    end

    def timeAddition(t1,t2)
      # +1 is to stay in the same zone, may be this cannot work correctly if the server is set to an other zone than UTC + 3
      temp1 = DateTime.strptime(t1+"+1",'%Y%m%d%H%M%S%z').to_time
      temp2 = DateTime.strptime(t2+"+1",'%Y%m%d%H%M%S%z').to_i
      res = temp1 + temp2
      return res.strftime('%Y%m%d%H%M%S')
    end

#argument is attempt_id
  def triangularTimecost(a_id)
  end
#================================= Station Keeping ==============================================
  def stationKeepingRawScore(a_id)
    timecost=stationKeepingTimecost(a_id)
    return stationKeepingRawScoreWithTimecost(timecost)
  end

  def stationKeepingRawScoreWithTimecost(timecost)
    ans=10-(300-timecost).abs/10*1.0 
    return 0 > ans ? 0 : ans
  end

  def stationKeepingTimecost(a_id)
    a=Attempt.find_by(a_id)
    # find all markers for this mission
    markers=Marker.where(mission_id: a.mission.id).order('id')
    # sort all coordiantes based on time
    testCoords=a.coordinates.order('datetime')
    timecost=stationKeepingTimecostWithData(markers,testCoords)
    return timecost
  end
  
  def stationKeepingTimecostWithData(markers,testCoords)
    # begin to calculate the score
    i=0
    # At the begining , it should be out of polygon zone
    while (pInPolygon(testCoords[i], markers) > 0)
      i+=1
    end
    outflag=true
    
    while (pInPolygon(testCoords[i], markers) < 0 )
      i+=1
    end
    # starting to count the time
    outflag=false
    tstart=testCoords[i].datetime
    lastDatetime=testCoords[i].datetime
    i+=1
    warnflag=false
    twarn=0
    v=-1
    while (outflag==false)
      inp=pInPolygon(testCoords[i],markers)
      if (inp < 0)
        warnflag=true
        twarn+= datetimeAMinusB(testCoords[i].datetime,lastDatetime)
      else
        if warnflag==true
          warnflag=false
          twarn=0
        end
      end
  
      if (warnflag==true)
        if (twarn >= 10)
          tend=testCoords[i].datetime
          v=i
          outflag=true
        end
      end
      lastDatetime=testCoords[i].datetime
      i+=1
    end
    # there is always an error with 10s, when the boat wants to go out, the 10s was ignored
    return datetimeAMinusB(tend,tstart)-10
  end

  #http://alienryderflex.com/polygon/
  #0=> on the polygon  1 => in the polygon  -1 => out of the polygon
  #dp=desired point    p = polygon
  def pInPolygon(dp,p)
    #return p[3].latitude
    #return p[3].longitude
    j=p.length-1
    count=0 # count is the number of oddNodes
    # add the first coordinate to the polygon 
    p_y=dp.latitude.to_f
    p_x=dp.longitude.to_f
    for i in 0..(p.length-1)
      jy=p[j].latitude.to_f
      jx=p[j].longitude.to_f
      y=p[i].latitude.to_f
      x=p[i].longitude.to_f
      # if is one of the vertex in polygon
      if (y==p_y and x==p_x or jy==p_y and jx=p_x)
        return 0
      end
      if ( (y < p_y and jy >= p_y) or (jy < p_y and y >= p_y)) and  (x <= p_x or jx <= p_x)
          # the order of points of the  polygon is important, in this case is in clockwise or anti-clockwise
        lx=x + (p_y-y)/(jy-y)*(jx-x)
        if (lx==p_x)
          return 0
        end

        if (lx < p_x)
          count+=1
        end
      end
      j=i
    end
    if count % 2 == 0
      return -1
    else
      return 1
    end 
  end
  
#here a,b are string which refer to yyyymmddhhmmss
#Subtracting two DateTimes returns the elapsed time in days
  def datetimeAMinusB(a,b)
    return ((a.to_datetime-b.to_datetime)*24*60*60).to_i
  end
#========================= Area scanning ===========================



end
