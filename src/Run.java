import java.util.Scanner;

public class Run {

	public static void main(String[] args) {
		DbApp db = new DbApp();
		printAuth();
		
		db.dbConnect();
		

		String choice = null;
        Scanner scan = new Scanner(System.in);
        do {
        	printMenu();
            choice = scan.nextLine();
            switch (choice) {
            case "1":
            	String iP, da, ur, pd;
            	System.out.println("Give me the IP.");
            	iP = scan.nextLine();
            	System.out.println("Give me the database's name.");
            	da = scan.nextLine();
            	System.out.println("Give me the username.");
            	ur = scan.nextLine();
            	System.out.println("Give me the password.");
            	System.out.println("CAUTION: Your input will be displayed cuz I'm lazy...");
            	pd = scan.nextLine();
            	db.dbConnect(iP, da, ur, pd);
            	db.waitForEnter();
            	break;
            case "2":
            	db.commit();
            	db.waitForEnter();
            	break;
            case "3":
            	db.abort();
            	db.waitForEnter();
            	break;
            case "4":
            	String acYear, acSeason, courseCode;
            	System.out.println("Give acceptable inputs or face the ugly stack trace.");
            	System.out.println();
            	System.out.println("Give me academic year.");
            	acYear = scan.nextLine();
            	System.out.println("Give me academic season.");
            	acSeason = scan.nextLine();
            	System.out.println("Give me the courseCode.");
            	courseCode = scan.nextLine();
            	db.showStuds(acYear, acSeason, courseCode);
            	db.waitForEnter();
            	break;
            case "5":
            	String ye, se, amka;
            	System.out.println("Give acceptable inputs or face the ugly stack trace.");
            	System.out.println();
            	System.out.println("Give me academic year.");
            	ye = scan.nextLine();
            	System.out.println("Give me academic season.");
            	se = scan.nextLine();
            	System.out.println("Give me the student's AMKA.");
            	amka = scan.nextLine();
            	
            	db.gradeMenu(ye, se, amka);
            	db.waitForEnter();
            	break;
            case "q":
            	break;
            default :
                System.out.println("Invalid input");
            } // end of switch
        } while (!choice.equals("q"));
		
        
        System.out.println("GoodByyye amigoo =)");
        scan.close();
        db.dbDisconnect();
        return;
	}

	
	public static void printMenu() {
		System.out.println("-----------------------------------------------------------");
		System.out.println("1. Connect to a POSTGRES database.");
		System.out.println("2. Confirm commit / Start new.");
		System.out.println("3. Cancel commit / Start new.");
		System.out.println("4. Print students of a course on a specific semester.");
		System.out.println("5. Print student grades per semester.");
		System.out.println("___________________________________________Press q to quit.");
		System.out.println("-----------------------------------------------------------");
	}
	
	public static void printAuth() {
		System.out.println("===========================================================");
		System.out.println(" _  __     _ _   _  __     _ _               ____          ");
		System.out.println("| |/ /__ _| (_) | |/ /__ _| | |_ ___  __ _  |  _ \\ ___ ____");
		System.out.println("| ' // _` | | | | ' // _` | | __/ __|/ _` | | |_) / _ \\_  /");
		System.out.println("| . \\ (_| | | | | . \\ (_| | | |_\\__ \\ (_| | |  _ < (_) / /");
		System.out.println("|_|\\_\\__,_|_|_| |_|\\_\\__,_|_|\\__|___/\\__,_| |_| \\_\\___/___|");
		System.out.println("===========================================================");
		System.out.println("                            creative programming since 1998");
	}
}
