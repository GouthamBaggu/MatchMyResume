#     User selects Resume
#             ↓
#     User pastes Job Description
#             ↓
#     System cleans both
#             ↓
#     TF-IDF vectorization
#             ↓
#     Cosine similarity
#             ↓
# Display Score:

# Output: "Your Resume matches 78% with this Job"

install.packages("pdftools")
install.packages("text2vec")
install.packages("stringr")

library(pdftools)
library(text2vec)
library(stringr)
library(tm)

# Take resume
cat("Select the path of the resume (only pdf)")
resume <- file.choose()
if(tools::file_ext(resume) == "pdf"){
  
  resume_txt <- pdf_text(resume)
  resume_txt <- paste(resume_txt, collapse = " ")
  
}else{
  
  stop("Given file is not pdf. Please Try again")
  
}

#Take JD 
cat("Select the path of the JD")
jd <- file.choose()
if(tools::file_ext(jd) == "pdf"){
  
  jd_text <- pdf_text(jd)
  jd_text <- paste(jd_text,collapse = " ")
  
}else if(tools::file_ext(jd)=="txt"){
  
  jd_text <- readLines(jd,encoding = "UTF-8", warn = FALSE)
  jd_text <- paste(jd_text,collapse = " ")
  
}else{
  
  stop("Error can't go further")
  
}

#Cleaning the text
clean_text <- function(text){
  text <- tolower(text)
  text <- gsub("[^a-z]"," ",text)
  text <- removeWords(text, stopwords("english"))
  text <- stripWhitespace(text)
  
  return(text)
}


resume_txt <- clean_text(resume_txt)
jd_text <- clean_text(jd_text)

# Create Text Vector
documents <- c(jd_text,resume_txt)
it <- itoken(documents, progressbar = FALSE)
vocab <- create_vocabulary(it)
vectorizer <- vocab_vectorizer(vocab)

dtm <- create_dtm(it, vectorizer)

#TF-IDF

tfidf <- TfIdf$new()
dtm_tfidf <- fit_transform(dtm, tfidf)

# Cosine Similarity 
cosine_sim <- sim2(
  dtm_tfidf[1, , drop = FALSE],
  dtm_tfidf[2, , drop = FALSE],
  method = "cosine"
)

score <- round(as.numeric(cosine_sim) * 100, 2)

if(score >= 80){
  category <- "Good Match"
}else if(score >= 60){
  category <- "Moderate Match"
}else if(score >= 40){
  category <- "Weak Match"
}else{
  category <- "Poor Match"
}

# Extract vocabulary terms
terms <- colnames(dtm_tfidf)

# JD vector (row 1)
jd_vector <- as.numeric(dtm_tfidf[1, ])

# Resume vector (row 2)
resume_vector <- as.numeric(dtm_tfidf[2, ])

# Words present in JD but not in resume
missing_terms <- terms[jd_vector > 0 & resume_vector == 0]

# Show top 10 missing keywords
top_missing <- head(missing_terms, 10)

cat("\nSuggested Keywords to Improve Your Resume:\n")
print(top_missing)
cat("\n============================\n")
cat("      ATS EVALUATION RESULT\n")
cat("============================\n")
cat("Match Category:", category, "\n")
cat("Match Score:", score, "%\n")
cat("============================\n")
cat("Top missing Key words :",top_missing)