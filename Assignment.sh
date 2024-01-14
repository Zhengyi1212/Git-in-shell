# Display some blanks to make interface clean
function displayGap {
    echo ""
    echo "========================================"
    echo "" 
}

# This function is the text editor
function editor{
select choice in "Add to file" "Modify a word" "Modify a line" "insert a line" "show content"
do
case $choice in
	"Add to file")
		fileName=$1
		echo "Please click ctrl+C to stop: "
		cat >> $fileName
		break
		;;
	"Modify a word")
		fileName=$1
		echo "This is the file content: "
		cat $fileName | nl -b t -n ln
		read -p "Please enter the target line you want to modify: " line
		lineCount=$(wc -l < $fileName)
		if [[ "$line" -gt "$lineCount" ]] || [[ "$line" -eq 0 ]];then
		echo "invalid line"
		break;
		fi
		content=$(sed -n "${line}p" "$fileName")
		echo $content
		read -p "Please enter which word that you want to replace or delete: " targetWord
		word=$(echo "$content" | grep -o -w "$targetWord")
		if [[ -z "targetword" ]]; then
		echo "invalid input, please input something: "
		break
		fi
		wordCount=$(echo "$content" | grep -o "$word" | wc -l)
		echo "$wordCount"
		if [[ "$wordCount" -eq 0 ]]; then
		echo "There is no that word: "
		break
		fi
		if [[ "$wordCount" -eq 1 ]]; then
		read -p "Please enter the new word: " newWord
		sed -i "${line}s/\<${targetWord}\>/${newWord}/g" $fileName
		elif [[ "$wordCount" -gt 1 ]]; then
		echo "there is more than one target word: "
		read -p "Please enter which word you want to change: " ordinal
		read -p "Please enter the new word: " newWord
		sed -i "${line}s/\<${targetWord}\>/${newWord}/${ordinal}" "$fileName"
		fi
		break
		;;
	"Modify a line")
		fileName=$1
		echo "This is the file content: "
		cat $fileName | nl -b t -n ln
		read -p "Please enter the target line you want to modify: " line
		lineCount=$(wc -l <$fileName)
		if [[ "$line" -gt "lineCount" ]] || [[ "$line" -eq 0 ]]; then
		echo "invalid line"
		break;
		fi
		content=$(sed -n "${line}p" "$fileName")
		echo $content
		read -p "Please input the new line" newLine
		sed -i "$[line}s/.*/${newLine}/" "$fileName"
		break
		;;
	"insert a line")
		fileName=$1
		echo "This is the file content: "
		cat $fileName | nl -b t -n ln
		echo "which line you want to insert the new line? "
		read -p "New line will be insert after this line " position
		lineCount=$(wc -l < $fileName)
		if [[ "$line" -gt "$lineCount" ]] || [["$line" -eq 0 ]]; then
		echo "invalid input, please input something"
		break
		fi
		read -p "Please input the content: " content
		sed -i "${position}a\\${content}" "$fileName"
		break
		;;
	"show content")
		fileName=$1
		cat $fileName | nl -b t -n ln
		break
		;;
		*)
		echo "unknown action"
		break
		;;
esac
done
}   
				

function complie {
    fileName=$1
    if [ ! -z "$filename" ]; then
      echo "No corresponding .c file found"
      echo "Now exit program to let you create a .c file first!"
      exit 1
    fi
    # complie
    gcc "$fileName" -o "${fileName%.*}"
    if [ $? -eq 0 ]; then
      echo "Successfully complied given file!"
      echo "Now excute this file:"
      "./${filename%.*}"
    else
      echo "Failed to complie, please try again!"
      displayGap
      # give message of what was wrong
    fi
}

# This function create a new repository in total repository
function createRepository {
    echo "Create a repository........"
    read -p "please enter the name of the repository:" repository
    if  test -e ./$repository; 
    then
        echo "Failed to create a repository."
        echo "Existing a repository with the same name."
        return   #back to main menu
    else
        echo "Successfully create a repository."
        displayGap
        mkdir ./$repository
    fi
    sudo groupadd $repository #创建一个以repository为名字的工作组  
     echo "This would be a new assignment, please choose who is your co-worker:"
    awk -F: '$3 >= 1000 && $1 != "nobody" && $1 != ENVIRON["USER"] { print $1 }' /etc/passwd
    sudo usermod -aG "$repository" $(whoami)  
    # Add current user into the group
    while [ 1 ]; 
    do
        read -p "Please enter who you want to add to your group: " coworker 
        sudo usermod -aG "$repository" $coworker 
        # Add a co-worker
        echo "(Please enter ""exit"" to exit this process.)"
        if [[ "$coworker" == "exit" ]]; 
        then
            echo "exiting...... "
            break         
        fi
    done
    displayGap
    sudo chmod g+rwx ./$repository 
   #change the mode of this repository for secure
}

# This function add a new file into the repository
function addFile {
    echo "Create a new file and its corresponding log file in the repository......."
    read -p "please enter the name of the new file:" fileName
    touch ./$fileName
    groupName=$1
    logName="$fileName.log"
    echo "" >> $logName
    echo "================" >> $logName
    echo ""
    echo "Name:" >> $logName
    echo $(whoami) >> $logName
    echo "Date:" >> $logName
    echo $(date) >> $logName
    echo "Message:" >> $logName
    echo "" >> $logName
    echo "Modified content:" >> $logName
    echo  "" >> $logName
    echo "Version:" >> $logName
    echo "0" >> $logName
    sudo chown :"$groupName" "./$fileName" #改变所属组
    sudo chown :"$groupName" "./$logName"
    sudo chmod g+rwx "./$fileName" #给组rwx权限
    sudo chmod g+r "./$logName"
    if  test -e ./$fileName; 
    then
        echo "Create file successfully"
    else
        echo "Create file failed"
    fi
    cd ..
    displayGap
}

# This function display all the files in the given repository
function displayFiles {
    allFile="$(ls -A)"
    if [ ! -z "$allFile" ]; 
    then
        echo "These are all the files in this repository:"
        echo "$allFile"
    else
        echo "This is a empty repository"
        echo "You may want to create some files first!"
        displayGap
        return 0
    fi
}

# This function check out a given file and commit back to repository
function checkOutAndCommit {
    currentUser=$(whoami)
    while [ 1 ]; do
       read -p "Please enter the name of the file:" fileName
       firstLine=$(head -n 1 "./$fileName")
       # Check if the source of "cp" exists
       if [ ! -e $fileName ]; 
       then
           echo "Sorry, this file does not exist."
           displayGap
           break
       fi
       if [ -z "$firstLine" ]; then 
       sed -i "1i\\${currentUser}" "$fileName"  
       # The first line indicate who check this file out
       else 
       # if not empty, then there is someone using
       echo "This file is editing by your partner, please wait"
       exit 0
       fi
       cp -p ./$fileName ./ectype 
       nano ectype  # text editor
       echo "Do you want to commit this version to repository?"
       echo "(Your changes will not be saved if you do not commit)"  
       select choice in yes no;
       do 
           case $choice in
                 yes) 
                    logName="$fileName.log"  
                    sudo chmod g+rwx "./$logName"
                    echo "You want to commit!"
                    read -p "Please give a description of this change:" messageCommit
                    version=$(($(tail -n 1 "$logName")+1))
                    sed -i '1{ x;p;x;}' "$logName" 
                    # delete the first line after checking out
                    newFileName=${fileName}${version}   
                    cp -p ./ectype ./$newFileName 
                    rm ectype
                    echo "" >> "./$logName"
                    echo "================" >> "./$logName"
                    echo "Name:" >> "./$logName"
                    echo $(whoami) >> "./$logName"
                    echo "Date" >> "./$logName"
                    echo $(date) >> "./$logName"
                    echo "Message:" >> "./$logName"
                    echo $messageCommit >> "./$logName"
                    echo "Modified content:" >> "./$logName"
                    diff -y $fileName $newFileName >> "./$logName"
                    echo "Version:" >> "./$logName"
                    echo  $version >> "./$logName"
                    displayGap
                    break 2
                  
                 ;;
                no)
                    echo "You don't want to commit. New file has been deleted!"
                    echo "Now return to main menu"
                    cd ..
                    break 2
                 ;; 
                 *)
                    echo "This is not a valid option, please try again!"
                    sed -i '1{ x;p;x;}' "$fileName"
                    break
                 ;;
             esac   
        done 
    done
}


 # Make a big repository to store all repositoies
if test -e "/srv/totalRepository"; 
then
    echo "You have a total repository already."
    echo "Now enter the total repository!"
    displayGap
else 
    echo "Create a total repository for all repositories!" 
    echo "This need you enter your password." 
    displayGap
    sudo mkdir /srv/totalRepository    
    sudo chmod 777 /srv/totalRepository
fi
while [ true ]; do
    cd /srv/totalRepository
    echo "This is version control tool!"
    echo "====MAIN MENU===="
    echo "Please enter the choice:"
    select choice1 in "Create a new repository" "Search for a repository" "Exit ." ; 
    do
        case $choice1 in
        "Create a new repository")  
            echo "You want to create a new repository！"
            createRepository 
            break
            ;;
        "Search for a repository")  
            echo "You want to search a repository！"
            allRepository=$(ls -A)
            empty=$(echo -n"$allRepository" | wc -l)
            if [ $empty = 0 ]; then
                echo "Sorry, no available repository."
                echo "Maybe create a repository first."
                displayGap  
                break     #back to main
            fi
            echo "These are all the your repositories:"            
            echo "$allRepository" 
            read -p "PLease enter the name of the repository:" repoName
            if   [[ "$allRepository" != *"$repoName"* || -z $repoName  ]]; 
            then    
                echo "No repository found, return to main menu" 
                displayGap
                break     
            else                              
                cd ./$repoName
                displayGap     
            fi               
            #already in given repository            
            echo "Now in repository: $repoName"
            echo "====REPOSITORY MENU===="
            select choice2 in "Add a new file" "Display all the files of different version" "Complie a file" "Back to previous menu"; 
            do
                case $choice2 in
                    "Add a new file")
                        addFile $repoName
                        break
                    ;;       
                    "Display all the files of different version")
                        echo "(You can check where version had"
                        echo "been modified in corresponding log file!)"
                        displayFiles
                        allFiles=$(ls -A)
                        # Check if this is an empty repository
                        if [[ ! -z $allFiles ]]; 
                        then 
                        echo ""
                        echo "You can choose any version of a file"  
                        echo "and modify it after checking out"      
                        checkOutAndCommit
                        fi      
                        break
                    ;;
                    "Complie a file")
                        read -p "Please enter the name of the file you want to complie: " $name
                        complie 
                        break
                    ;;
                    "Back to previous menu")
                        echo "Now back to previous menu......"
                        displayGap
                        break
                    ;;    
                    *)
                    ;;   
                esac  
            done         
            cd ..     
            break  
            ;;
        "Exit .")
            exit 0
            ;;
        *)
            echo "This is not a valid option."
            displayGap 
            ;;
        esac
    done
done