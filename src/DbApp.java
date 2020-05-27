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
			this.startTransactions(); //set auto commit to false
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void dbConnect() { //for faster testing
		try {
			conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/postgres", "postgres", "#YOUR_PASSWORD_HERE");
			System.out.println("Connection is successfull!");
			this.startTransactions();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void startTransactions() { //as given
		try {
			conn.setAutoCommit(false);
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void commit() { //as given
		try {
			conn.commit();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void abort() { //as given
		try {
			conn.rollback();
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
			//System.out.println("found that semester_id is: "+semID);
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
		Statement st; //variable to execute statments
        Scanner sc = new Scanner(System.in);
        //ArrayList of Savepoint objects to have the ability to go back on your changes
        ArrayList<Savepoint> arli = new ArrayList<Savepoint>();
        int pointer = -1; //to implement array list as FIFO
		try {
			String cho = "";
			st = conn.createStatement();
			//it would be fun if some naive guy made acY to be "2016';--"... A crash could mean RCE ;) 
			//since i know i don't have the characters "--" in my query, i could detect if there is one, and return the function without executing..
			//maybe later ...
			
			//first calculate the semester_id
			ResultSet res = st.executeQuery("select semester_id from \"Semester\" where academic_year='"+acY+"' and academic_season='"+acS+"';");
			res.next();
			int semID = res.getInt(1);
			//System.out.println("found that semester_id is: "+semID);
			res.close();
			
			do { //while user input is not 0
				//query in the loop for the grade to be up-to-date
				//and a user friendly programm with no need to remember all changes you've done
				res = st.executeQuery("select row_number() OVER ()::integer ind, s.code, s.title, s.labGrade, s.finalGrade\r\n" + 
						"from( select\r\n" + 
						"r.course_code code, co.course_title title, coalesce(r.lab_grade,0) labGrade, coalesce(r.final_grade,0) finalGrade \r\n" + 
						"from \"Register\" r natural join \"Course\" co \r\n" + 
						"where r.amka='"+am+"' and r.serial_number='"+semID+"' order by code ASC) s\r\n" + 
						"order by ind ASC;");
				
				String initialTable = ""; //to have an easy access on the response from base
				
				while (res.next()) { //read query
					//add to the table for the ease-of-access
					initialTable += res.getInt(1)+"\t| code="+res.getString(2)+"| title="+res.getString(3)+" labGrade="+res.getBigDecimal(4)+" | finalGrade="+res.getBigDecimal(5)+"\n";
					//also print
					System.out.println(res.getInt(1)+"\t| code="+res.getString(2)+"| title="+res.getString(3)+" labGrade="+res.getBigDecimal(4)+" | finalGrade="+res.getBigDecimal(5));
				}
				//now ok, lets switch on user's input
				System.out.println("I'm listening for input");
				System.out.println("0 is return, -1 is one change back, any other number is the course to change grades");
	            cho = sc.nextLine();
	            switch (cho) {
	            case "0":
	            	System.out.println("Don't forget to commit your changes");
	            	conn.setSavepoint(); //if not defined, commit cannot bee made
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
		            this.waitForEnter();
	            	break;
	            default:
	            	System.out.println("You chose to change the number ID: "+cho);
	            	//save the state
	            	Savepoint s = conn.setSavepoint();
	            	//and add it to the stack
	            	arli.add(s);
	            	pointer += 1;
	            	
	            	//make changes
	            	int position;
	            	BigDecimal labGrade, finalGrade; //big decimal is a numeric in postgre standart
	            	position = Integer.parseInt(cho); //the position on the response table
	            	//res.absolute(position);
	            	String[] lines = initialTable.split(System.getProperty("line.separator")); //split response table by new lines
	            	System.out.println("You chose:\n"+lines[position-1]);
	            	String courseCode = lines[position-1].substring(10, 17); //the course code is always at that character points

		            System.out.println("Give the LAB grade");
			        cho = sc.nextLine();
		            labGrade = new BigDecimal(cho);
		            System.out.println("Give the FINAL grade");
			        cho = sc.nextLine();
		            finalGrade = new BigDecimal(cho);

		            //lets change the "Register" columns of lab and final grades
		            //where the AMKA is defined from the method's input and the course code and semester ID, as calculated above
		            PreparedStatement pst = conn.prepareStatement("UPDATE \"Register\" "
		            		+ "SET final_grade=?,"
		            		+ "lab_grade=? WHERE amka=? AND "
		            		+ "course_code=? AND serial_number=?");
		            //set the prepared statement parameters
		            pst.setBigDecimal(1, finalGrade);
		            pst.setBigDecimal(2, labGrade);
		            pst.setInt(3,Integer.parseInt(am)); //also convert String amka to Int amka
		            pst.setString(4,courseCode);
		            pst.setInt(5, semID);
		            //execute the prepared statement
		            pst.executeUpdate();
		            pst.close();
		            this.waitForEnter();
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
