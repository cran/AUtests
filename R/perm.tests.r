#' Permutation testing
#'
#' Calculates permutation p-values for testing independence in 2x2 case-control tables.
#' @param m0 Number of control subjects
#' @param m1 Number of case subjects
#' @param r0 Number of control subjects exposed
#' @param r1 Number of case subjects exposed
#' @param lowthresh A threshold for probabilities below to be considered as zero. Defaults to 1e-12.
#' @return A vector of permutation p-values, computed under score, likelihood ratio, Wald, and Firth tests.
#' @examples
#' perm.tests(15000, 5000, 30, 25)

perm.tests = function(m0, m1, r0, r1, lowthresh=1E-12)
{
 	if (r0 == 0 & r1 == 0)
	{
		return(c(score.p = 1, lr.p = 1, wald.p = 1, wald0.p = 1, firth.p = 1))
	}
	
 	if (r0 == m0 & r1 == m1)
	{
		return(c(score.p = 1, lr.p = 1, wald.p = 1, wald0.p = 1, firth.p = 1))
	}

	if (is.na(m0 + m1 + r0 + r1))
	{
		return(c(score.p = NA, lr.p = NA, wald.p = NA, wald0.p = NA, firth.p = NA))
	}
	

	p = (r0+r1)/(m0+m1) # observed p
	
	# Score test
 	ybar = m1/(m0+m1)
 	t = r1*(1-ybar) - r0*ybar
 	sd.t = sqrt((1-ybar)^2*m1*p*(1-p) + ybar^2*m0*p*(1-p))

	# Likelihood ratio test	
 	p0 = r0/m0
 	p1 = r1/m1
 	pL = (r0+r1)/(m0+m1)

 	llik.null = dbinom(r0, m0, pL, log=T) + dbinom(r1, m1, pL, log=T)
 	llik.alt  = dbinom(r0, m0, p0, log=T) + dbinom(r1, m1, p1, log=T)
 	llr = llik.alt - llik.null

	# Wald test (with regularization)
 	reg = 0.5
 	betahat = log( (r1+reg)/(m1-r1+reg)/((r0+reg)/(m0-r0+reg)) )
 	sehat = sqrt(1/(r0+reg) + 1/(r1+reg) + 1/(m0-r0+reg) + 1/(m1-r1+reg))
 	waldT = betahat/sehat

	# Wald test (no regularization)
 	reg0 = 0
 	betahat0 = log( (r1+reg0)/(m1-r1+reg0)/((r0+reg0)/(m0-r0+reg0)) )
 	sehat0 = sqrt(1/(r0+reg0) + 1/(r1+reg0) + 1/(m0-r0+reg0) + 1/(m1-r1+reg0))
 	waldT0 = betahat0/sehat0
	
	# Firth test
 	y = c(1,1,0,0)
 	x = c(1,0,1,0)
 	data = data.frame(y = y, x = x)
	m.firth = logistf(y~x, data=data, weights=c(r1, m1-r1, r0, m0-r0))
	firth.t = sum(c(-2, 2)*m.firth$loglik)
	firth.p = m.firth$prob[2]

	# Permutation testing
 	dd = data.frame(r0x=0:(r0+r1))
 	dd$r1x = r0 + r1 - dd$r0x
  delrows = which(with(dd, r0x > m0 | r1x > m1))
  if (length(delrows) > 0) dd = dd[-delrows,]
 	dd$prob = dhyper(dd$r1x, r0+r1, m0+m1-r0-r1, m1)
	
	dd$firthx = sapply(1:nrow(dd), function(xx) sum(c(-2,2)*(logistf(y~x, data=data, 
	weights=c(dd$r1x[xx], m1-dd$r1x[xx], dd$r0x[xx], m0-dd$r0x[xx]))$loglik)))
	
 	dd$px = with(dd, (r0x+r1x)/(m0+m1) )
 	dd$tx = with(dd, r1x*(1-ybar) - r0x*ybar )
 	dd$sd.tx = with(dd, sqrt((1-ybar)^2*m1*px*(1-px) + ybar^2*m0*px*(1-px)))

 	dd$p0x = with(dd, r0x/m0)
 	dd$p1x = with(dd, r1x/m1)
 	dd$pLx = with(dd, (r0x+r1x)/(m0+m1))

 	dd$llik.nullx = with(dd, dbinom(r0x, m0, pLx, log=T) + dbinom(r1x, m1, pLx, log=T))
 	dd$llik.altx = with(dd, dbinom(r0x, m0, p0x, log=T) + dbinom(r1x, m1, p1x, log=T))
 	dd$llrx = with(dd, llik.altx - llik.nullx)

	dd$betahatw = with(dd, log(r1x+ reg) - log(m1-r1x+reg) - log(r0x+reg) + log(m0-r0x+reg) )
 	dd$sehatw = with(dd, sqrt(1/(r0x+reg) + 1/(r1x+reg) + 1/(m0-r0x+reg) + 1/(m1-r1x+reg)) )
 	dd$waldTw = with(dd, betahatw/sehatw)
	
	dd$betahatw0 = with(dd, log(r1x+ reg0) - log(m1-r1x+reg0) - log(r0x+reg0) + log(m0-r0x+reg0) )
 	dd$sehatw0 = with(dd, sqrt(1/(r0x+reg0) + 1/(r1x+reg0) + 1/(m0-r0x+reg0) + 1/(m1-r1x+reg0)) )
 	dd$waldTw0 = with(dd, betahatw0/sehatw0)
	infrows = which( with(dd, abs(betahatw0) == Inf) )
  p.inf = sum(dd[infrows, "prob"])

	matchrow = which( with(dd, r0x==r0 & r1x==r1) )
  p.obs = dd[matchrow, "prob"]
  dd = dd[-matchrow,]


 	dd.score = p.obs + sum(dd[abs(dd$tx/dd$sd.tx) >= abs(t/sd.t),]$prob)
	dd.lrt   = p.obs + sum(dd[dd$llrx >= llr,]$prob)
 	dd.wald  = p.obs + sum(dd[abs(dd$waldTw) >= abs(waldT),]$prob)
	dd.firth = p.obs + sum(dd[dd$firthx >= firth.t,]$prob)
  dd = dd[-which( with(dd, abs(betahatw0) == Inf) ),]
  dd.wald0 = p.obs + sum(dd[abs(dd$waldTw0) >= abs(waldT0),]$prob) + p.inf

  c(score.p = dd.score, lr.p = dd.lrt, wald.p = dd.wald, wald0.p = dd.wald0, firth.p = dd.firth)
}


