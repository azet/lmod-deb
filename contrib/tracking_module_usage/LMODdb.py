from __future__ import print_function
from time       import sleep
import os, sys, re, base64, time, json
dirNm, execName = os.path.split(os.path.realpath(sys.argv[0]))
sys.path.append(os.path.realpath(dirNm))

import MySQLdb, ConfigParser, getpass
import warnings, inspect
from BeautifulTbl import BeautifulTbl
warnings.filterwarnings("ignore", "Unknown table.*")
def __LINE__():
    try:
        raise Exception
    except:
        return sys.exc_info()[2].tb_frame.f_back.f_lineno

def __FILE__():
    return inspect.currentframe().f_code.co_filename

#print ("file: '%s', line: %d" % (__FILE__(), __LINE__()), file=sys.stderr)

def convertToInt(s):
  """
  Convert to string to int.  Protect against bad input.
  @param s: Input string
  @return: integer value.  If bad return 0.
  """
  try:
    value = int(s)
  except ValueError:
    value = 0
  return value

class LMODdb(object):
  """
  This LMODdb class opens the Lmod database and is responsible for
  all the database interactions.
  """
  s_build_userT   = True
  userT           = {}
  s_build_moduleT = True
  moduleT         = {}

  def __init__(self, confFn):
    """ Initialize the class and save the db config file. """
    self.__host   = None
    self.__user   = None
    self.__passwd = None
    self.__db     = None
    self.__conn   = None
    self.__confFn = confFn

  def __readFromUser(self):
    """ Ask user for database access info. (private) """

    self.__host   = raw_input("Database host:")
    self.__user   = raw_input("Database user:")
    self.__passwd = getpass.getpass("Database pass:")
    self.__db     = raw_input("Database name:")

  def __readConfig(self):
    """ Read database access info from config file. (private)"""
    confFn = self.__confFn
    try:
      config=ConfigParser.ConfigParser()
      config.read(confFn)
      self.__host    = config.get("MYSQL","HOST")
      self.__user    = config.get("MYSQL","USER")
      self.__passwd  = base64.b64decode(config.get("MYSQL","PASSWD"))
      self.__db      = config.get("MYSQL","DB")
    except ConfigParser.NoOptionError, err:
      sys.stderr.write("\nCannot parse the config file\n")
      sys.stderr.write("Switch to user input mode...\n\n")
      self.__readFromUser()

  def connect(self, databaseName = None):
    """
    Public interface to connect to DB.
    @param db:  If this exists it will be used.

    """
    if(os.path.exists(self.__confFn)):
      self.__readConfig()
    else:
      self.__readFromUser()

    n = 200
    for i in xrange(0,n+1):
      try:
        self.__conn = MySQLdb.connect (self.__host,self.__user,self.__passwd)
        if (databaseName):
          cursor = self.__conn.cursor()

          # If MySQL version < 4.1, comment out the line below
          cursor.execute("SET SQL_MODE=\"NO_AUTO_VALUE_ON_ZERO\"")
          cursor.execute("USE "+self.db())
        break


      except MySQLdb.Error, e:
        if (i < n):
          sleep(i*0.1)
          print ("failed to connect trying again: ",i)
          pass
        else:
          print ("LMODdb(%d): Error %d: %s" % (i, e.args[0], e.args[1]), file=sys.stderr)
          raise
    return self.__conn


  def db(self):
    """ Return name of db"""
    return self.__db


  def dump_db(self):

    userA   = None
    moduleA = None

    query = ""
    try:
      conn   = self.connect()
      cursor = conn.cursor()
      query  = "USE "+self.db()
      conn.query(query)
      
      # extract user names from userT table.

      query = "SELECT max(user_id) from userT"
      cursor.execute(query)
      sz    = cursor.fetchone()[0]
      userA = [ None ] * (sz+1)

      query = "SELECT user_id, user from userT"
      cursor.execute(query)
      numRows = cursor.rowcount
      for i in xrange(numRows):
        row            = cursor.fetchone()
        user_id        = row[0]
        user           = row[1]
        userA[user_id] = user

      moduleA = []

      # extract moduleT table
      query = "SELECT max(mod_id) from moduleT"
      cursor.execute(query)
      sz      = cursor.fetchone()[0]
      moduleA = [ None ] * (sz+1)

      query = "SELECT mod_id, path, module, syshost from moduleT"
      cursor.execute(query)
      numRows = cursor.rowcount
      for i in xrange(numRows):
        row             = cursor.fetchone()
        mod_id          = row[0]
        path            = row[1]
        module          = row[2]
        syshost         = row[3]
        moduleA[mod_id] = {'path' : path, 'module' : module, 'syshost' : syshost}


      # extract join_user_module table:
      query = "SELECT user_id, mod_id, UNIX_TIMESTAMP(date) from join_user_module"
      cursor.execute(query)
      numRows = cursor.rowcount
      for i in xrange(numRows):
        row     = cursor.fetchone()
        user    = userA[int(row[0])]
        modT    = moduleA[int(row[1])]
        date    = str(row[2])
        t       = {'user': user, 'path': modT['path'], 'module' : modT['module'], 'syshost': modT['syshost'], 'date' : date }
        print(json.dumps(t))

    except Exception as e:
      print("dump_db(): ",e)
      sys.exit(1)


  def data_to_db(self, dataT):
    """
    Store data into database.
    @param dataT: The data table.
    """

    query = ""
    try:
      conn   = self.connect()
      cursor = conn.cursor()
      query  = "USE "+self.db()
      conn.query(query)
      query  = "START TRANSACTION"
      conn.query(query)

      ############################################################
      # build userT if necessary.

      if (LMODdb.s_build_userT):
        LMODdb.s_build_userT = False

        query = "SELECT user_id, user from userT"
        cursor.execute(query)

        numRows = cursor.rowcount
        for i in xrange(numRows):
          row = cursor.fetchone()
          user_id = int(row[0])
          user    = row[1]
          LMODdb.userT[user] = user_id
          
      ############################################################
      # Get user_id
      user    = dataT['user']
      user_id = LMODdb.userT.get(user)

      if (user_id == None):
        
        try:
          query = "INSERT INTO userT VALUES(NULL, %s)"
          cursor.execute(query,[user])
          user_id = cursor.lastrowid
        except Exception as e:
          query = "SELECT user_id FROM userT WHERE user = %s"
          cursor.execute(query,[user])
          if (cursor.rowcount > 0):
            user_id = int(cursor.fetchone()[0])
          else:
            print("Failed to insert \"%s\" into userT, Aborting!" % user)
            sys.exit(1)

        LMODdb.userT[user] = user_id
       
      #############################################################
      # build moduleT

      if (LMODdb.s_build_moduleT):
        LMODdb.s_build_moduleT = False

        query = "SELECT mod_id, path, module, syshost FROM moduleT"
        cursor.execute(query)
        numRows = cursor.rowcount

        for i in xrange(numRows):
          row     = cursor.fetchone()
          mod_id  = row[0]
          path    = row[1]
          module  = row[2]
          syshost = row[3]
          LMODdb.moduleT[(syshost,path)] =  mod_id
          
      ############################################################
      # get mod_id
      
      syshost = dataT['syshost']
      path    = dataT['path']
      key     = (syshost, path)
      mod_id  = LMODdb.moduleT.get(key)
      if (mod_id == None):

        module = dataT['module']
        try:
          query = "INSERT INTO moduleT VALUES(NULL, %s, %s, %s)"
          cursor.execute(query,(path, module, syshost))
          mod_id = cursor.lastrowid
        except Exception as e:
          query = "SELECT mod_id FROM moduleT WHERE syshost = %s and path = %s "
          cursor.execute(query,(syshost, path))
          if (cursor.rowcount > 0):
            mod_id = int(cursor.fetchone()[0])
          else:
            print("Failed to insert (\"%s\",\"%s\") moduleT, Aborting!" % (syshost, path))
            sys.exit(1)

        LMODdb.moduleT[key] = mod_id
        
        
      ############################################################
      # Insert into join_user_module table
      
      dateTm = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(float(dataT['time'])))
      query  = "INSERT into join_user_module VALUES(NULL, %s, %s, %s) "
      cursor.execute(query,(user_id, mod_id, dateTm))

      ##################################################################
      # Step 4: Commit everything to db.

      query = "COMMIT"
      conn.query(query)
      conn.close()

    except Exception as e:
      print("data_to_db(): ",e)
      sys.exit(1)

  def counts(self, sqlPattern, syshost, startDate, endDate):
    query = ""
    try:
      conn   = self.connect()
      cursor = conn.cursor()
      query  = "USE "+self.db()
      conn.query(query)

      dateTest = ""
      if (startDate != "unknown"):
        dateTest = " and t2.date >= '" + startDate + "'"

      if (endDate != "unknown"):
        dateTest = dateTest + " and t2.date < '" + endDate + "'"

      if (sqlPattern == "") :
        sqlPattern == "%"

      query = "SELECT t1.path, t1.syshost, count(distinct(t2.user_id)) as c2 from moduleT as t1, "  +\
              "join_user_module as t2 where t1.path like %s and t1.mod_id = t2.mod_id " +\
              "and t1.syshost like %s " + dateTest + " group by t2.mod_id order by c2 desc"

      cursor.execute(query,( sqlPattern, syshost))
      numRows = cursor.rowcount

      resultA = []

      resultA.append(["Module path", "Syshost", "Distinct Users" ])
      resultA.append(["-----------", "-------", "--------------"])
      for i in xrange(numRows):
        row = cursor.fetchone()
        resultA.append([row[0],row[1],row[2]])

      conn.close()

      return resultA


    except Exception as e:
      print("counts(): ",e)
      sys.exit(1)

  def usernames(self, sqlPattern, syshost, startDate, endDate):
    query = ""
    try:
      conn   = self.connect()
      cursor = conn.cursor()
      query  = "USE "+self.db()
      conn.query(query)

      dateTest = ""
      if (startDate != "unknown"):
        dateTest = " and t2.date >= '" + startDate + "'"

      if (endDate   != "unknown"):
        dateTest = dateTest + " and t2.date < '" + endDate + "'"

      if (sqlPattern == "") :
        sqlPattern == "%"

      query =  "SELECT t1.path, t1.syshost, t3.user as c2 from moduleT as t1, join_user_module "       +\
               "as t2, userT as t3 where t1.path like  %s  and t1.mod_id = t2.mod_id "     +\
               "and t1.syshost like  %s " + dateTest +" and t3.user_id = t2.user_id "      +\
               "group by c2 order by c2"

      cursor.execute(query, ( sqlPattern, syshost))
      numRows = cursor.rowcount

      resultA = []
      resultA.append(["Module path", "Syshost", "User Name"])
      resultA.append(["-----------", "-------", "---------"])


      for i in xrange(numRows):
        row = cursor.fetchone()
        resultA.append([row[0],row[1],row[2]])

      conn.close()

      return resultA


    except Exception as e:
      print("usernames(): ",e)
      sys.exit(1)


  def modules_used_by(self, username, syshost, startDate, endDate):
    query = ""
    try:
      conn   = self.connect()
      cursor = conn.cursor()
      query  = "USE "+self.db()
      conn.query(query)

      dateTest = ""
      if (startDate != "unknown"):
        dateTest = " and t2.date >= '" + startDate + "'"

      if (endDate != "unknown"):
        dateTest = dateTest + " and t2.date < '" + endDate + "'"

      query =  "SELECT t1.path as c1, t1.syshost, t3.user as c2 from moduleT as t1, join_user_module "   +\
               "as t2, userT as t3 where t3.user =  %s  and t1.mod_id = t2.mod_id "          +\
               "and t1.syshost like %s "+ dateTest + " and t3.user_id = t2.user_id "         +\
               "group by c1 order by c1"

      cursor.execute(query, ( username, syshost ))
      numRows = cursor.rowcount

      resultA = []
      resultA.append(["Module path", "Syshost", "User Name"])
      resultA.append(["-----------", "-------", "---------"])


      for i in xrange(numRows):
        row = cursor.fetchone()
        resultA.append([row[0],row[1],row[2]])

      conn.close()

      return resultA


    except Exception as e:
      print("modules_used_by(): ",e)
      sys.exit(1)
