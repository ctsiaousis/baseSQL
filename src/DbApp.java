import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Savepoint;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Random;
import java.util.Scanner;

public class DbApp {
	private Connection conn;
	
	public DbApp() {
		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
			System.out.println("Driver not found!");
		}
	}
	public void dbDisconnect() {
		try {
			conn.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void dbConnect(String ip, String dbName, String ursName, String ursPass) {
		try {
			conn = DriverManager.getConnection("jdbc:postgresql://"+ip+":5432/"+dbName, ursName, ursPass);
			System.out.println("Connection is successfull!");
			startTransactions();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void dbConnect() {
		try {
			conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/postgres", "postgres", "3b37affe");
			System.out.println("Connection is successfull!");
			startTransactions();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void startTransactions() {
		try {
			conn.setAutoCommit(false);
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void commit() {
		try {
			conn.commit();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void abort() {
		try {
			conn.rollback();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void insertLabs() {
		Random rand = new Random();
		try {
			PreparedStatement pst = conn.prepareStatement("insert into \"Lab\" values((select max(lab_code)+1 from \"Lab\"),?,?,?,?)");
			
			for (int i=0; i<10 ; i++) {
				pst.setInt(1,rand.nextInt(5)+1);
				pst.setString(2, "Lab Title "+i);
				pst.setString(3, "Lab Desc "+i);
				pst.setNull(4,java.sql.Types.INTEGER);
				
				pst.executeUpdate();
			}
			
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void waitForEnter() {
		Scanner scn = new Scanner(System.in);
		System.out.println("Press Enter ...");
		scn.nextLine();
		//scn.close(); //if left here closes the main scanner... damn java
	}
	
	public void showStuds(String acY, String acS, String cCo) {
		try {
			Statement st = conn.createStatement();
			
			ResultSet res = st.executeQuery("select semester_id from \"Semester\" where academic_year='"+acY+"' and academic_season='"+acS+"';");
			res.next();
			int semID = res.getInt(1);
			System.out.println("found that semester_id is: "+semID);
			res.close();
			
			res = st.executeQuery("select s.name, s.surname from \"Student\" s where exists (select amka from \"Register\" r where r.serial_number='"+semID+"' and r.course_code='"+cCo+"' and r.amka=s.amka);");
			while (res.next()) {
				System.out.println("name="+res.getString(1)+" surname="+res.getString(2));
			}
			res.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		
	}
	
	public void gradeMenu(String acY, String acS, String am) {
		Statement st;
        Scanner sc = new Scanner(System.in);

        ArrayList<Savepoint> arli = new ArrayList<Savepoint>();
        int pointer = -1; //to implement arli as FIFO
		try {
			String cho = "";
			st = conn.createStatement();
			//it would be fun if some naive guy made acY to be "2016';--"... A crash could mean RCE ;) 
			//since i know i don't have the characters "--" in my query, i could detect if there is one, and return the function without executing..
			//maybe later ...
			ResultSet res = st.executeQuery("select semester_id from \"Semester\" where academic_year='"+acY+"' and academic_season='"+acS+"';");
			res.next();
			int semID = res.getInt(1);
			System.out.println("found that semester_id is: "+semID);
			res.close();
			
			do {
				//get table every time for the grade to be up-to-date
				res = st.executeQuery("select row_number() OVER ()::integer ind, s.code, s.title, s.labGrade, s.finalGrade\r\n" + 
						"from( select\r\n" + 
						"r.course_code code, co.course_title title, coalesce(r.lab_grade,0) labGrade, coalesce(r.final_grade,0) finalGrade \r\n" + 
						"from \"Register\" r natural join \"Course\" co \r\n" + 
						"where r.amka='"+am+"' and r.serial_number='"+semID+"' order by code ASC) s\r\n" + 
						"order by ind ASC;");
				
				String initialTable = ""; //to have an easy access on the first response from base
				
				while (res.next()) {
					//add to the table for ease-of-access
					initialTable += res.getInt(1)+"\t| code="+res.getString(2)+"| title="+res.getString(3)+" labGrade="+res.getBigDecimal(4)+" | finalGrade="+res.getBigDecimal(5)+"\n";
					//also print
					System.out.println(res.getInt(1)+"\t| code="+res.getString(2)+"| title="+res.getString(3)+" labGrade="+res.getBigDecimal(4)+" | finalGrade="+res.getBigDecimal(5));
				}
				//now ok, lets switch
				System.out.println("I'm listening for input");
				System.out.println("0 is return, -1 is one change back, any other number is the course to change grades");
	            cho = sc.nextLine();
	            switch (cho) {
	            case "0":
	            	System.out.println("Don't forget to commit your changes");
	            	conn.setSavepoint();
	            	return;
	            case "-1":
	            	if (arli.size() == 0) {
	            		System.out.println("No more savepoints to roll back to..");
	            	}else {
	            		//remove one change
	            		conn.rollback(arli.get(pointer));
	            		arli.remove(pointer);
	            		pointer -= 1;
	            		System.out.println("Went a step back..");
	            	}
	            	break;
	            default:
	            	System.out.println("You chose to change the number ID: "+cho);
	            	//save the state
	            	Savepoint s = conn.setSavepoint();
	            	arli.add(s);
	            	pointer += 1;
	            	
	            	//make changes
	            	int position;
	            	BigDecimal labGrade, finalGrade;
	            	position = Integer.parseInt(cho);
	            	//res.absolute(position);
	            	String[] lines = initialTable.split(System.getProperty("line.separator"));
	            	System.out.println("You chose:\n"+lines[position-1]);
	            	String courseCode = lines[position-1].substring(10, 17);

		            System.out.println("Give the LAB grade");
			        cho = sc.nextLine();
		            labGrade = new BigDecimal(cho);
		            System.out.println("Give the FINAL grade");
			        cho = sc.nextLine();
		            finalGrade = new BigDecimal(cho);

		            //lets change
		            PreparedStatement pst = conn.prepareStatement("UPDATE \"Register\" "
		            		+ "SET final_grade=?,"
		            		+ "lab_grade=? WHERE amka=? AND "
		            		+ "course_code=? AND serial_number=?");
		            // set the prepared statement parameters
		            pst.setBigDecimal(1, finalGrade);
		            pst.setBigDecimal(2, labGrade);
		            pst.setInt(3,Integer.parseInt(am));
		            pst.setString(4,courseCode);
		            pst.setInt(5, semID);
		            //
		            pst.executeUpdate();
		            pst.close();
	            	break;
	            }
			}while(cho != "0");
			sc.close();
			res.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		//not suposed to get here...
		return;
	}
	
	

}
