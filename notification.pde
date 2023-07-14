enum NotificationType { Door, PersonMoveHome, PersonMoveWork, Meeting, PersonStatus, ObjectMove, ApplianceStateChange, PackageDelivery, Message }

class Notification {
   
  int timestamp;
  NotificationType type; // door, person_move, object_move, appliance_state_change, package_delivery, message
  String note;
  String location;
  String tag;
  String flag;
  int priority;
  
  public Notification(JSONObject json) {
    this.timestamp = json.getInt("timestamp");
    //time in milliseconds for playback from sketch start
    
    String typeString = json.getString("type");
    
    try {
      this.type = NotificationType.valueOf(typeString);
    }
    catch (IllegalArgumentException e) {
      throw new RuntimeException(typeString + " is not a valid value for enum NotificationType.");
    }
    
    
    if (json.isNull("note")) {
      this.note = "";
    }
    else {
      this.note = json.getString("note");
    }
    
    if (json.isNull("location")) {
      this.location = "";
    }
    else {
      this.location = json.getString("location");      
    }
    
    if (json.isNull("tag")) {
      this.tag = "";
    }
    else {
      this.tag = json.getString("tag");      
    }
    
    if (json.isNull("flag")) {
      this.flag = "";
    }
    else {
      this.flag = json.getString("flag");      
    }
    
    this.priority = json.getInt("priority");
    //1-3 levels (1 is highest, 3 is lowest)    
  }
  
  public int getTimestamp() { return timestamp; }
  public NotificationType getType() { return type; }
  public String getNote() { return note; }
  public String getLocation() { return location; }
  public String getTag() { return tag; }
  public String getFlag() { return flag; }
  public int getPriorityLevel() { return priority; }
  
  public String toString() {
      String output = getType().toString() + ": ";
      output += "(location: " + getLocation() + ") ";
      output += "(tag: " + getTag() + ") ";
      output += "(flag: " + getFlag() + ") ";
      output += "(priority: " + getPriorityLevel() + ") ";
      output += "(note: " + getNote() + ") ";
      return output;
    }
}
