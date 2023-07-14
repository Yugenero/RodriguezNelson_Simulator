import java.util.Calendar;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

class NotificationServer {
  
  Boolean debugMode = true; //set this to false to turn off the println statements on each Notification below
  
  Timer timer;
  Calendar calendar;
  private ArrayList<NotificationListener> listeners;
  private ArrayList<Notification> currentNotifications;

  public NotificationServer() {
    timer = new Timer();
    listeners = new ArrayList<NotificationListener>();
    calendar = Calendar.getInstance();
  }
  
  //loads and schedules all tasks
  //you should register all listeners before calling this method
  public void loadEventStream(String eventDataJSON) {
    currentNotifications = this.getNotificationDataFromJSON(loadJSONArray(eventDataJSON));
    
    //Starting the NotificationServer (scheduling tasks) 
    for (int i = 0; i < currentNotifications.size(); i++) { //<>//
      this.scheduleTask(currentNotifications.get(i));
    }
    
  }
  
  public void stopEventStream() {
    if (timer != null)
      timer.cancel(); //stop all currently scheduled tasks
    timer = new Timer();  //create a new Timer for future scheduling
  }
  
  public ArrayList<Notification> getCurrentNotifications() {
    return currentNotifications;
  }
  
  public ArrayList<Notification> getNotificationDataFromJSON(JSONArray values) {
    ArrayList<Notification> notifications = new ArrayList<Notification>();
    for (int i = 0; i < values.size(); i++) {
      println(values.getJSONObject(i));
      notifications.add(new Notification(values.getJSONObject(i)));
    }
    return notifications;
  }

  public void scheduleTask(Notification notification) {
    timer.schedule(new NotificationTask(this, notification), notification.getTimestamp());
  }
  
  public void addListener(NotificationListener listenerToAdd) {
    listeners.add(listenerToAdd);
  }
  
  public void notifyListeners(Notification notification) {
    if (debugMode)
      println("<NotificationServer> " + notification.toString());
    for (int i=0; i < listeners.size(); i++) {
      listeners.get(i).notificationReceived(notification);
    }
  }
  

  class NotificationTask extends TimerTask {
    
    NotificationServer server;
    Notification notification;
    
    public NotificationTask(NotificationServer server, Notification notification) {
      super();
      this.server = server;
      this.notification = notification;
    }
    
    public void run() {
      server.notifyListeners(notification);
    }
    
  }
}
